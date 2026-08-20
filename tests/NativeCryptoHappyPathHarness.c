#include "crypto.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(condition, message)                                             \
    do {                                                                      \
        if (!(condition)) {                                                   \
            fprintf(stderr, "FAILED: %s (line %d)\n", (message), __LINE__); \
            return 1;                                                         \
        }                                                                     \
    } while (0)

/* crypto.c also contains get_md5(), whose unrelated formatting helper lives
 * in utils.c.  Keep this executable focused on the exact production crypto
 * implementation without pulling plist and logger dependencies into the KAT.
 * The stub is never called by this harness. */
char *
utils_hex_to_string(const unsigned char *hex, int hex_len)
{
    (void) hex;
    (void) hex_len;
    return NULL;
}

static int
test_aes_128_ctr_nist_split_and_reset(void)
{
    /* NIST SP 800-38A, F.5.1, first AES-128 CTR block. */
    static const unsigned char key[16] = {
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
        0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
    };
    static const unsigned char counter[16] = {
        0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
        0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
    };
    static const unsigned char plaintext[16] = {
        0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
        0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a
    };
    static const unsigned char ciphertext[16] = {
        0x87, 0x4d, 0x61, 0x91, 0xb6, 0x20, 0xe3, 0x26,
        0x1b, 0xef, 0x68, 0x64, 0x99, 0x0d, 0xb6, 0xce
    };
    unsigned char one_shot[16] = {0};
    unsigned char split[16] = {0};
    unsigned char after_reset[16] = {0};
    unsigned char partial_probe[5] = {0};

    aes_ctx_t *one_shot_ctx = aes_ctr_init(key, counter);
    aes_ctx_t *split_ctx = aes_ctr_init(key, counter);
    CHECK(one_shot_ctx != NULL && split_ctx != NULL,
          "production AES-CTR contexts initialize");

    CHECK(aes_ctr_encrypt(one_shot_ctx, plaintext, one_shot,
                          (int) sizeof(plaintext)) == 0,
          "one-shot AES-CTR update succeeds");
    CHECK(memcmp(one_shot, ciphertext, sizeof(ciphertext)) == 0,
          "one-shot AES-CTR output matches the NIST vector");

    CHECK(aes_ctr_encrypt(split_ctx, plaintext, split, 5) == 0,
          "first five-byte AES-CTR update succeeds");
    CHECK(aes_ctr_encrypt(split_ctx, plaintext + 5, split + 5, 11) == 0,
          "second eleven-byte AES-CTR update succeeds on the same context");
    CHECK(memcmp(split, ciphertext, sizeof(ciphertext)) == 0,
          "split AES-CTR updates match the one-shot NIST output");

    /* Leave non-zero block bookkeeping immediately before reset.  A reset
     * must restore both the EVP state and the wrapper's block offset. */
    CHECK(aes_ctr_encrypt(split_ctx, plaintext, partial_probe,
                          (int) sizeof(partial_probe)) == 0,
          "partial AES-CTR probe succeeds before reset");
    CHECK(aes_ctr_reset(split_ctx) == 0,
          "AES-CTR reset succeeds after a partial update");
    CHECK(aes_ctr_start_fresh_block(split_ctx) == 0,
          "fresh-block request is a no-op immediately after reset");
    CHECK(aes_ctr_encrypt(split_ctx, plaintext, after_reset, 5) == 0 &&
              aes_ctr_encrypt(split_ctx, plaintext + 5, after_reset + 5,
                              11) == 0,
          "split AES-CTR updates remain reusable after reset");
    CHECK(memcmp(after_reset, ciphertext, sizeof(ciphertext)) == 0,
          "reset AES-CTR context repeats the NIST output");

    aes_ctr_destroy(split_ctx);
    aes_ctr_destroy(one_shot_ctx);
    return 0;
}

int
main(void)
{
    CHECK(test_aes_128_ctr_nist_split_and_reset() == 0,
          "AES-128 CTR happy-path contract passes");
    puts("Native production crypto happy-path checks passed (AES-128 CTR NIST split/reset).");
    return 0;
}
