#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#endif

#include "worker_lifecycle.h"

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef _WIN32
#error This lifecycle harness currently targets the supported Windows build.
#endif

#define CHECK(condition, message)                                             \
    do {                                                                      \
        if (!(condition)) {                                                   \
            fprintf(stderr, "FAILED: %s (line %d)\n", (message), __LINE__); \
            ExitProcess(1);                                                   \
        }                                                                     \
    } while (0)

typedef struct harness_ops_state_s {
    volatile LONG create_calls;
    volatile LONG join_calls;
    volatile LONG fail_create;
    volatile LONG fail_join;
} harness_ops_state_t;

typedef enum worker_mode_e {
    WORKER_MODE_NATURAL,
    WORKER_MODE_BLOCKED,
    WORKER_MODE_SELF_STOP,
    WORKER_MODE_ACCEPT,
    WORKER_MODE_RECV
} worker_mode_t;

typedef struct harness_case_s {
    worker_lifecycle_t lifecycle;
    pthread_mutex_t gate_mutex;
    pthread_cond_t gate_cond;
    harness_ops_state_t ops_state;
    worker_mode_t mode;
    volatile LONG entered;
    volatile LONG exited_count;
    int wake_seen;
    int allow_exit;
    int hold_after_wake;
    int self_stop_result;
    int callbacks[16];
    int callback_count;
    volatile LONG wake_calls;
    volatile LONG cleanup_calls;
    volatile LONG resource_close_calls;
    volatile LONG listener_shutdown_calls;
    volatile LONG stream_shutdown_calls;
    int resource_open;
    SOCKET listener;
    SOCKET stream;
    SOCKET client;
} harness_case_t;

typedef struct stop_call_s {
    harness_case_t *test_case;
    int result;
    volatile LONG entered;
    volatile LONG returned;
} stop_call_t;

static harness_ops_state_t *active_ops_state;

static int
harness_create(thread_handle_t *thread, THREAD_RETVAL (*func)(void *),
               void *arg)
{
    CHECK(active_ops_state != NULL, "injected create has active state");
    InterlockedIncrement(&active_ops_state->create_calls);
    if (InterlockedCompareExchange(&active_ops_state->fail_create, 0, 0)) {
        return EAGAIN;
    }
    return pthread_create(thread, NULL, func, arg);
}

static int
harness_join(thread_handle_t thread, void **retval)
{
    int result;
    CHECK(active_ops_state != NULL, "injected join has active state");
    InterlockedIncrement(&active_ops_state->join_calls);
    result = pthread_join(thread, retval);
    if (result == 0 &&
        InterlockedCompareExchange(&active_ops_state->fail_join, 0, 0)) {
        /* The real thread is reaped first.  The synthetic result exercises
         * the helper's deliberately terminal join-failure state without
         * leaking an OS thread from this test process. */
        return EINVAL;
    }
    return result;
}

static thread_handle_t
harness_self(void)
{
    return pthread_self();
}

static int
harness_equal(thread_handle_t left, thread_handle_t right)
{
    return pthread_equal(left, right);
}

static const worker_lifecycle_ops_t harness_ops = {
    harness_create,
    harness_join,
    harness_self,
    harness_equal
};

static void
record_callback(harness_case_t *test_case, int running)
{
    pthread_mutex_lock(&test_case->gate_mutex);
    CHECK(test_case->callback_count <
              (int) (sizeof(test_case->callbacks) /
                     sizeof(test_case->callbacks[0])),
          "callback evidence buffer is bounded");
    test_case->callbacks[test_case->callback_count++] = running;
    pthread_cond_broadcast(&test_case->gate_cond);
    pthread_mutex_unlock(&test_case->gate_mutex);
}

static void
mark_entered(harness_case_t *test_case)
{
    InterlockedExchange(&test_case->entered, 1);
    pthread_mutex_lock(&test_case->gate_mutex);
    pthread_cond_broadcast(&test_case->gate_cond);
    pthread_mutex_unlock(&test_case->gate_mutex);
}

static void
mark_exited(harness_case_t *test_case)
{
    /* The start owner emits true while holding this same lifecycle lock.
     * Taking it before false makes even an immediately exiting worker retain
     * the externally visible true -> false ordering. */
    worker_lifecycle_mark_exited(&test_case->lifecycle);
    record_callback(test_case, 0);
    pthread_mutex_lock(&test_case->gate_mutex);
    InterlockedIncrement(&test_case->exited_count);
    pthread_cond_broadcast(&test_case->gate_cond);
    pthread_mutex_unlock(&test_case->gate_mutex);
}

static void
harness_wake_locked(void *opaque)
{
    harness_case_t *test_case = opaque;
    CHECK(test_case->lifecycle.running == 0,
          "stop publishes running=false before any wake action");
    InterlockedIncrement(&test_case->wake_calls);

    if (test_case->mode == WORKER_MODE_RECV &&
               test_case->stream != INVALID_SOCKET) {
        CHECK(shutdown(test_case->stream, SD_BOTH) == 0,
              "published stream shuts down while waking recv");
        InterlockedIncrement(&test_case->stream_shutdown_calls);
    }

    pthread_mutex_lock(&test_case->gate_mutex);
    test_case->wake_seen = 1;
    pthread_cond_broadcast(&test_case->gate_cond);
    pthread_mutex_unlock(&test_case->gate_mutex);
}

static void
harness_cleanup_unlocked(void *opaque)
{
    harness_case_t *test_case = opaque;
    InterlockedIncrement(&test_case->cleanup_calls);
    if (test_case->resource_open) {
        test_case->resource_open = 0;
        InterlockedIncrement(&test_case->resource_close_calls);
    }
    if (test_case->listener != INVALID_SOCKET) {
        SOCKET listener = test_case->listener;
        test_case->listener = INVALID_SOCKET;
        CHECK(closesocket(listener) == 0, "listener cleanup succeeds");
        InterlockedIncrement(&test_case->resource_close_calls);
    }
    if (test_case->stream != INVALID_SOCKET) {
        SOCKET stream = test_case->stream;
        test_case->stream = INVALID_SOCKET;
        CHECK(closesocket(stream) == 0, "stream cleanup succeeds");
        InterlockedIncrement(&test_case->resource_close_calls);
    }
}

static THREAD_RETVAL
harness_worker(void *opaque)
{
    harness_case_t *test_case = opaque;
    mark_entered(test_case);

    if (test_case->mode == WORKER_MODE_SELF_STOP) {
        test_case->self_stop_result = worker_lifecycle_stop(
            &test_case->lifecycle, harness_wake_locked,
            NULL, harness_cleanup_unlocked, test_case);
    } else if (test_case->mode == WORKER_MODE_ACCEPT) {
        while (worker_lifecycle_should_run(&test_case->lifecycle)) {
            fd_set read_fds;
            struct timeval timeout = {0, 5000};
            FD_ZERO(&read_fds);
            FD_SET(test_case->listener, &read_fds);
            int selected = select(0, &read_fds, NULL, NULL, &timeout);
            CHECK(selected != SOCKET_ERROR,
                  "nonblocking listener select remains valid");
            if (selected > 0 && FD_ISSET(test_case->listener, &read_fds)) {
                SOCKET accepted = accept(test_case->listener, NULL, NULL);
                if (accepted != INVALID_SOCKET) {
                    closesocket(accepted);
                } else {
                    CHECK(WSAGetLastError() == WSAEWOULDBLOCK,
                          "nonblocking accept reports only would-block");
                }
            }
        }
    } else if (test_case->mode == WORKER_MODE_RECV) {
        while (worker_lifecycle_should_run(&test_case->lifecycle)) {
            char byte = 0;
            int received = recv(test_case->stream, &byte, 1, 0);
            if (received > 0) {
                continue;
            }
            if (received == 0) {
                break;
            }
            int socket_error = WSAGetLastError();
            CHECK(socket_error == WSAETIMEDOUT ||
                      socket_error == WSAEWOULDBLOCK ||
                      !worker_lifecycle_should_run(&test_case->lifecycle),
                  "timed recv reports timeout or observes stop");
        }

        worker_lifecycle_lock(&test_case->lifecycle);
        SOCKET stream = test_case->stream;
        test_case->stream = INVALID_SOCKET;
        worker_lifecycle_unlock(&test_case->lifecycle);
        if (stream != INVALID_SOCKET) {
            CHECK(closesocket(stream) == 0,
                  "worker remains the sole accepted-stream closer");
            InterlockedIncrement(&test_case->resource_close_calls);
        }
    } else if (test_case->mode == WORKER_MODE_BLOCKED) {
        pthread_mutex_lock(&test_case->gate_mutex);
        while (!test_case->wake_seen) {
            pthread_cond_wait(&test_case->gate_cond,
                              &test_case->gate_mutex);
        }
        while (test_case->hold_after_wake && !test_case->allow_exit) {
            pthread_cond_wait(&test_case->gate_cond,
                              &test_case->gate_mutex);
        }
        pthread_mutex_unlock(&test_case->gate_mutex);
    }

    mark_exited(test_case);
    return NULL;
}

static void
case_init(harness_case_t *test_case, worker_mode_t mode)
{
    memset(test_case, 0, sizeof(*test_case));
    test_case->mode = mode;
    test_case->listener = INVALID_SOCKET;
    test_case->stream = INVALID_SOCKET;
    test_case->client = INVALID_SOCKET;
    CHECK(pthread_mutex_init(&test_case->gate_mutex, NULL) == 0,
          "case gate mutex initializes");
    CHECK(pthread_cond_init(&test_case->gate_cond, NULL) == 0,
          "case gate condition initializes");
    active_ops_state = &test_case->ops_state;
    CHECK(worker_lifecycle_init_with_ops(&test_case->lifecycle,
                                         &harness_ops) == 0,
          "production lifecycle initializes with injected operations");
}

static void
case_destroy(harness_case_t *test_case)
{
    if (test_case->client != INVALID_SOCKET) {
        closesocket(test_case->client);
        test_case->client = INVALID_SOCKET;
    }
    worker_lifecycle_destroy(&test_case->lifecycle);
    pthread_cond_destroy(&test_case->gate_cond);
    pthread_mutex_destroy(&test_case->gate_mutex);
    active_ops_state = NULL;
}

static int
case_start(harness_case_t *test_case)
{
    int result;
    worker_lifecycle_lock(&test_case->lifecycle);
    result = worker_lifecycle_start_thread_locked(
        &test_case->lifecycle, harness_worker, test_case);
    if (result == 1) {
        record_callback(test_case, 1);
    }
    worker_lifecycle_unlock(&test_case->lifecycle);
    return result;
}

static int
wait_for_value(volatile LONG *value, LONG minimum, DWORD timeout_ms)
{
    ULONGLONG deadline = GetTickCount64() + timeout_ms;
    do {
        if (InterlockedCompareExchange(value, 0, 0) >= minimum) {
            return 1;
        }
        Sleep(1);
    } while (GetTickCount64() < deadline);
    return InterlockedCompareExchange(value, 0, 0) >= minimum;
}

static THREAD_RETVAL
stop_thread(void *opaque)
{
    stop_call_t *call = opaque;
    InterlockedExchange(&call->entered, 1);
    call->result = worker_lifecycle_stop(
        &call->test_case->lifecycle, harness_wake_locked,
        NULL, harness_cleanup_unlocked, call->test_case);
    InterlockedExchange(&call->returned, 1);
    return NULL;
}

static void
allow_blocked_exit(harness_case_t *test_case)
{
    pthread_mutex_lock(&test_case->gate_mutex);
    test_case->allow_exit = 1;
    pthread_cond_broadcast(&test_case->gate_cond);
    pthread_mutex_unlock(&test_case->gate_mutex);
}

static void
assert_true_false_pairs(const harness_case_t *test_case, int pairs)
{
    CHECK(test_case->callback_count == pairs * 2,
          "successful starts emit exactly one true/false callback pair");
    for (int i = 0; i < pairs; i++) {
        CHECK(test_case->callbacks[i * 2] == 1 &&
                  test_case->callbacks[i * 2 + 1] == 0,
              "running callbacks are ordered true then false");
    }
}

static void
test_create_failure_and_restart(void)
{
    harness_case_t test_case;
    case_init(&test_case, WORKER_MODE_NATURAL);
    InterlockedExchange(&test_case.ops_state.fail_create, 1);
    CHECK(case_start(&test_case) == -1, "thread-create failure is reported");
    CHECK(test_case.callback_count == 0,
          "thread-create failure emits no running callback");
    CHECK(worker_lifecycle_is_joined(&test_case.lifecycle),
          "thread-create failure leaves no join debt");
    CHECK(!worker_lifecycle_is_running_or_joinable(&test_case.lifecycle),
          "thread-create failure rolls back running state");

    InterlockedExchange(&test_case.ops_state.fail_create, 0);
    CHECK(case_start(&test_case) == 1,
          "a successful start follows create rollback");
    CHECK(wait_for_value(&test_case.exited_count, 1, 3000),
          "retry worker exits naturally");
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_COMPLETED,
          "successful retry is externally joined");
    CHECK(test_case.ops_state.create_calls == 2,
          "create was attempted once for each start");
    CHECK(test_case.ops_state.join_calls == 1,
          "only the successful worker is joined");
    assert_true_false_pairs(&test_case, 1);
    case_destroy(&test_case);
}

static void
test_natural_exit_join_debt_and_restart(void)
{
    harness_case_t test_case;
    case_init(&test_case, WORKER_MODE_NATURAL);
    CHECK(case_start(&test_case) == 1, "natural-exit worker starts");
    CHECK(wait_for_value(&test_case.exited_count, 1, 3000),
          "natural-exit worker reaches its tail");
    CHECK(!worker_lifecycle_is_joined(&test_case.lifecycle),
          "natural exit preserves external join debt");
    CHECK(worker_lifecycle_is_running_or_joinable(&test_case.lifecycle),
          "natural exit remains externally reapable");
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_COMPLETED,
          "first stop pays natural-exit join debt");
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_ALREADY_JOINED,
          "second stop cannot double-join");

    test_case.entered = 0;
    CHECK(case_start(&test_case) == 1,
          "same object restarts after external reap");
    CHECK(wait_for_value(&test_case.exited_count, 2, 3000),
          "restarted worker exits naturally");
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_COMPLETED,
          "restarted worker is joined exactly once");
    CHECK(test_case.ops_state.join_calls == 2,
          "two successful generations create two joins");
    assert_true_false_pairs(&test_case, 2);
    case_destroy(&test_case);
}

static void
test_join_failure_retains_debt(void)
{
    harness_case_t test_case;
    case_init(&test_case, WORKER_MODE_NATURAL);
    CHECK(case_start(&test_case) == 1, "join-failure worker starts");
    CHECK(wait_for_value(&test_case.exited_count, 1, 3000),
          "join-failure worker exits naturally");
    InterlockedExchange(&test_case.ops_state.fail_join, 1);
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_JOIN_FAILED,
          "injected join failure is observable");
    CHECK(!worker_lifecycle_is_joined(&test_case.lifecycle),
          "failed join retains debt");
    CHECK(test_case.cleanup_calls == 0,
          "resource cleanup does not run before a successful join");
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_JOIN_FAILED,
          "terminal join failure is returned without an unsafe retry");
    CHECK(test_case.ops_state.join_calls == 1 &&
              test_case.cleanup_calls == 0,
          "terminal join failure never retries or cleans uncertain ownership");

    /* harness_join already reaped the real thread before returning its
     * synthetic error.  Repair only the test object's state so the production
     * helper can release its mutex/condition; production never performs this
     * repair and must refuse destroy after a real join failure. */
    worker_lifecycle_lock(&test_case.lifecycle);
    test_case.lifecycle.join_failed = 0;
    test_case.lifecycle.joined = 1;
    worker_lifecycle_unlock(&test_case.lifecycle);
    case_destroy(&test_case);
}

static void
test_concurrent_stops_join_once(void)
{
    harness_case_t test_case;
    stop_call_t first = {0};
    stop_call_t second = {0};
    thread_handle_t first_thread;
    thread_handle_t second_thread;

    case_init(&test_case, WORKER_MODE_BLOCKED);
    test_case.hold_after_wake = 1;
    CHECK(case_start(&test_case) == 1, "blocked worker starts");
    CHECK(wait_for_value(&test_case.entered, 1, 3000),
          "blocked worker reaches wait point");
    first.test_case = &test_case;
    second.test_case = &test_case;
    CHECK(pthread_create(&first_thread, NULL, stop_thread, &first) == 0,
          "first concurrent stopper starts");
    CHECK(wait_for_value(&test_case.wake_calls, 1, 3000),
          "one stopper claims wake ownership");
    CHECK(pthread_create(&second_thread, NULL, stop_thread, &second) == 0,
          "second concurrent stopper starts");
    CHECK(wait_for_value(&second.entered, 1, 3000),
          "second stopper enters the production stop path");
    Sleep(30);
    CHECK(!second.returned,
          "second stopper waits behind the join owner");
    CHECK(test_case.ops_state.join_calls == 1,
          "only one concurrent stopper calls join");
    allow_blocked_exit(&test_case);
    CHECK(pthread_join(first_thread, NULL) == 0 &&
              pthread_join(second_thread, NULL) == 0,
          "both concurrent stoppers return");
    CHECK((first.result == WORKER_LIFECYCLE_STOP_COMPLETED &&
           second.result == WORKER_LIFECYCLE_STOP_WAITED) ||
              (second.result == WORKER_LIFECYCLE_STOP_COMPLETED &&
               first.result == WORKER_LIFECYCLE_STOP_WAITED),
          "one stopper owns completion and one reports waiting");
    CHECK(test_case.ops_state.join_calls == 1 &&
              test_case.cleanup_calls == 1 &&
              test_case.wake_calls == 1,
          "concurrent stop performs one wake, join, and cleanup");
    assert_true_false_pairs(&test_case, 1);
    case_destroy(&test_case);
}

static void
test_serialized_destroy_follows_join(void)
{
    harness_case_t test_case;

    case_init(&test_case, WORKER_MODE_BLOCKED);
    CHECK(case_start(&test_case) == 1, "serialized-destroy worker starts");
    CHECK(wait_for_value(&test_case.entered, 1, 3000),
          "serialized-destroy worker reaches wait point");
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_COMPLETED,
          "serialized owner stops and joins before destroy");
    CHECK(worker_lifecycle_is_joined(&test_case.lifecycle),
          "serialized destroy observes completed join state");
    CHECK(test_case.ops_state.join_calls == 1 &&
              test_case.cleanup_calls == 1,
          "serialized stop performs one join and cleanup");
    worker_lifecycle_destroy(&test_case.lifecycle);
    pthread_cond_destroy(&test_case.gate_cond);
    pthread_mutex_destroy(&test_case.gate_mutex);
    active_ops_state = NULL;
}

static void
test_self_stop_defers_join_and_close(void)
{
    harness_case_t test_case;
    case_init(&test_case, WORKER_MODE_SELF_STOP);
    test_case.resource_open = 1;
    CHECK(case_start(&test_case) == 1, "self-stop worker starts");
    CHECK(wait_for_value(&test_case.exited_count, 1, 3000),
          "self-stop worker reaches its tail");
    CHECK(test_case.self_stop_result == WORKER_LIFECYCLE_STOP_SELF,
          "worker detects self-stop without self-join");
    CHECK(test_case.ops_state.join_calls == 0 &&
              test_case.cleanup_calls == 0 &&
              test_case.resource_close_calls == 0,
          "self-stop defers join and resource close to an external owner");
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_COMPLETED,
          "external stop reaps a self-stopped worker");
    CHECK(test_case.ops_state.join_calls == 1 &&
              test_case.cleanup_calls == 1 &&
              test_case.resource_close_calls == 1,
          "unsupported-codec-style self-stop cannot double-close resources");
    assert_true_false_pairs(&test_case, 1);
    case_destroy(&test_case);
}

static SOCKET
create_loopback_listener(unsigned short *port)
{
    SOCKET listener = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    struct sockaddr_in address;
    int address_length = sizeof(address);
    CHECK(listener != INVALID_SOCKET, "loopback listener socket opens");
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = 0;
    CHECK(bind(listener, (struct sockaddr *) &address, sizeof(address)) == 0,
          "loopback listener binds");
    CHECK(listen(listener, 1) == 0, "loopback listener listens");
    CHECK(getsockname(listener, (struct sockaddr *) &address,
                      &address_length) == 0,
          "loopback listener reports its port");
    *port = ntohs(address.sin_port);
    return listener;
}

static void
test_nonblocking_accept_stop(void)
{
    harness_case_t test_case;
    unsigned short port;
    u_long nonblocking = 1;
    ULONGLONG stop_started;
    ULONGLONG stop_elapsed;
    case_init(&test_case, WORKER_MODE_ACCEPT);
    test_case.listener = create_loopback_listener(&port);
    CHECK(port != 0, "accept test receives an ephemeral port");
    CHECK(ioctlsocket(test_case.listener, FIONBIO, &nonblocking) == 0,
          "listener enters the production nonblocking mode");
    CHECK(case_start(&test_case) == 1, "accept worker starts");
    CHECK(wait_for_value(&test_case.entered, 1, 3000),
          "accept worker reaches bounded select loop");
    Sleep(20);
    stop_started = GetTickCount64();
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_COMPLETED,
          "bounded listener polling observes stop and allows join");
    stop_elapsed = GetTickCount64() - stop_started;
    CHECK(stop_elapsed < 1500,
          "nonblocking accept/select stop remains bounded");
    CHECK(test_case.listener_shutdown_calls == 0 &&
              test_case.resource_close_calls == 1 &&
              test_case.cleanup_calls == 1,
          "listener is closed exactly once after worker join");
    assert_true_false_pairs(&test_case, 1);
    case_destroy(&test_case);
}

static void
test_timed_recv_stop(void)
{
    harness_case_t test_case;
    struct sockaddr_in address;
    unsigned short port;
    SOCKET listener;
    DWORD receive_timeout = 5;
    ULONGLONG stop_started;
    ULONGLONG stop_elapsed;

    case_init(&test_case, WORKER_MODE_RECV);
    listener = create_loopback_listener(&port);
    test_case.client = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    CHECK(test_case.client != INVALID_SOCKET, "recv client socket opens");
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = htons(port);
    CHECK(connect(test_case.client, (struct sockaddr *) &address,
                  sizeof(address)) == 0,
          "recv client connects to loopback");
    test_case.stream = accept(listener, NULL, NULL);
    CHECK(test_case.stream != INVALID_SOCKET,
          "recv test accepts its stream before worker start");
    CHECK(setsockopt(test_case.stream, SOL_SOCKET, SO_RCVTIMEO,
                     (const char *) &receive_timeout,
                     sizeof(receive_timeout)) == 0,
          "recv test installs the exact Windows five-millisecond timeout");
    CHECK(closesocket(listener) == 0,
          "recv setup listener closes before lifecycle evidence");
    CHECK(case_start(&test_case) == 1, "recv worker starts");
    CHECK(wait_for_value(&test_case.entered, 1, 3000),
          "recv worker reaches blocking call");
    Sleep(20);
    stop_started = GetTickCount64();
    CHECK(worker_lifecycle_stop(&test_case.lifecycle, harness_wake_locked,
                                NULL, harness_cleanup_unlocked, &test_case) ==
              WORKER_LIFECYCLE_STOP_COMPLETED,
          "stream stop and bounded receive timeout allow join");
    stop_elapsed = GetTickCount64() - stop_started;
    CHECK(stop_elapsed < 1000,
          "timed recv observes stop within its bounded polling contract");
    CHECK(test_case.stream_shutdown_calls == 1,
          "stop owner shuts the published stream down once");
    CHECK(test_case.resource_close_calls == 1 &&
              test_case.cleanup_calls == 1,
          "worker closes the accepted stream exactly once");
    assert_true_false_pairs(&test_case, 1);
    case_destroy(&test_case);
}

int
main(void)
{
    setvbuf(stdout, NULL, _IONBF, 0);
    WSADATA winsock;
    CHECK(WSAStartup(MAKEWORD(2, 2), &winsock) == 0,
          "Winsock initializes for blocking socket tests");

    puts("CASE create-failure-restart");
    test_create_failure_and_restart();
    puts("CASE natural-exit-restart");
    test_natural_exit_join_debt_and_restart();
    puts("CASE terminal-join-failure");
    test_join_failure_retains_debt();
    puts("CASE concurrent-stop");
    test_concurrent_stops_join_once();
    puts("CASE serialized-destroy");
    test_serialized_destroy_follows_join();
    puts("CASE self-stop");
    test_self_stop_defers_join_and_close();
    puts("CASE nonblocking-accept");
    test_nonblocking_accept_stop();
    puts("CASE timed-recv");
    test_timed_recv_stop();

    CHECK(WSACleanup() == 0, "Winsock cleanup succeeds");
    puts("Native worker lifecycle executable checks passed (8 scenarios).");
    return 0;
}
