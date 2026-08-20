param(
    [string]$LibUxPlayRoot = "",
    [string]$CompilerPath = "",
    [int]$TimeoutSeconds = 20
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "FAILED: $Message"
    }
}

function Assert-Match(
    [string]$Text,
    [string]$Pattern,
    [string]$Message
) {
    Assert-True ([regex]::IsMatch(
        $Text, $Pattern,
        [Text.RegularExpressions.RegexOptions]::Multiline -bor
        [Text.RegularExpressions.RegexOptions]::Singleline)) $Message
}

function Assert-NoMatch(
    [string]$Text,
    [string]$Pattern,
    [string]$Message
) {
    Assert-True (-not [regex]::IsMatch(
        $Text, $Pattern,
        [Text.RegularExpressions.RegexOptions]::Multiline -bor
        [Text.RegularExpressions.RegexOptions]::Singleline)) $Message
}

function Assert-MatchCount(
    [string]$Text,
    [string]$Pattern,
    [int]$Expected,
    [string]$Message
) {
    $options = [Text.RegularExpressions.RegexOptions]::Multiline -bor
        [Text.RegularExpressions.RegexOptions]::Singleline
    $actual = [regex]::Matches($Text, $Pattern, $options).Count
    Assert-True ($actual -eq $Expected) `
        "$Message (expected $Expected, found $actual)"
}

function Assert-InOrder(
    [string]$Text,
    [string[]]$Fragments,
    [string]$Message
) {
    $offset = 0
    foreach ($fragment in $Fragments) {
        $index = $Text.IndexOf(
            $fragment, $offset, [StringComparison]::Ordinal)
        Assert-True ($index -ge 0) `
            "$Message (missing or out of order: $fragment)"
        $offset = $index + $fragment.Length
    }
}

function Get-SourceSlice(
    [string]$Text,
    [string]$Start,
    [string]$End,
    [string]$Name
) {
    $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
    Assert-True ($startIndex -ge 0) "$Name start marker exists"
    $endIndex = $Text.IndexOf(
        $End, $startIndex + $Start.Length, [StringComparison]::Ordinal)
    Assert-True ($endIndex -gt $startIndex) "$Name end marker follows start"
    return $Text.Substring($startIndex, $endIndex - $startIndex)
}

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($LibUxPlayRoot)) {
    $LibUxPlayRoot = Join-Path (Split-Path -Parent $projectRoot) `
        "upstream-uxplay-windows\libuxplay"
}
if ([string]::IsNullOrWhiteSpace($CompilerPath)) {
    $CompilerPath = Join-Path (
        Split-Path -Parent (Split-Path -Parent (
            Split-Path -Parent (Split-Path -Parent $projectRoot)))) `
        "msys64\ucrt64\bin\gcc.exe"
}

$libRoot = (Resolve-Path -LiteralPath $LibUxPlayRoot).Path
$compiler = (Resolve-Path -LiteralPath $CompilerPath).Path
$ucrtRoot = Split-Path -Parent (Split-Path -Parent $compiler)
$opensslInclude = Join-Path $ucrtRoot "include"
$cryptoImportLibrary = Join-Path $ucrtRoot "lib\libcrypto.dll.a"

$cryptoSource = Join-Path $libRoot "lib\crypto.c"
$cryptoHeader = Join-Path $libRoot "lib\crypto.h"
$pairingSource = Join-Path $libRoot "lib\pairing.c"
$mirrorBufferSource = Join-Path $libRoot "lib\mirror_buffer.c"
$raopBufferSource = Join-Path $libRoot "lib\raop_buffer.c"
$handlersSource = Join-Path $libRoot "lib\raop_handlers.h"
$ntpSource = Join-Path $libRoot "lib\raop_ntp.c"
$ntpHeader = Join-Path $libRoot "lib\raop_ntp.h"
$rtpSource = Join-Path $libRoot "lib\raop_rtp.c"
$rtpHeader = Join-Path $libRoot "lib\raop_rtp.h"
$mirrorParserSource = Join-Path $libRoot "lib\mirror_payload_parser.c"
$mirrorParserHeader = Join-Path $libRoot "lib\mirror_payload_parser.h"
$mirrorSource = Join-Path $libRoot "lib\raop_rtp_mirror.c"
$raopHeader = Join-Path $libRoot "lib\raop.h"
$httpRequestSource = Join-Path $libRoot "lib\http_request.c"
$httpRequestHeader = Join-Path $libRoot "lib\http_request.h"
$httpdSource = Join-Path $libRoot "lib\httpd.c"
$fairplaySource = Join-Path $libRoot "lib\fairplay_playfair.c"
$videoRendererSource = Join-Path $libRoot "renderers\video_renderer.c"
$audioRendererSource = Join-Path $libRoot "renderers\audio_renderer.c"
$uxplaySource = Join-Path $libRoot "uxplay.cpp"
$harnessSource = Join-Path $PSScriptRoot "NativeCryptoHappyPathHarness.c"

foreach ($path in @(
    $cryptoSource,
    $cryptoHeader,
    $pairingSource,
    $mirrorBufferSource,
    $raopBufferSource,
    $handlersSource,
    $ntpSource,
    $ntpHeader,
    $rtpSource,
    $rtpHeader,
    $mirrorParserSource,
    $mirrorParserHeader,
    $mirrorSource,
    $raopHeader,
    $httpRequestSource,
    $httpRequestHeader,
    $httpdSource,
    $fairplaySource,
    $videoRendererSource,
    $audioRendererSource,
    $uxplaySource,
    $harnessSource,
    $opensslInclude,
    $cryptoImportLibrary
)) {
    Assert-True (Test-Path -LiteralPath $path) `
        "required native core contract input exists: $path"
}

$cryptoText = Get-Content -LiteralPath $cryptoSource -Raw
$cryptoHeaderText = Get-Content -LiteralPath $cryptoHeader -Raw
$pairingText = Get-Content -LiteralPath $pairingSource -Raw
$mirrorBufferText = Get-Content -LiteralPath $mirrorBufferSource -Raw
$raopBufferText = Get-Content -LiteralPath $raopBufferSource -Raw
$handlersText = Get-Content -LiteralPath $handlersSource -Raw
$ntpText = Get-Content -LiteralPath $ntpSource -Raw
$ntpHeaderText = Get-Content -LiteralPath $ntpHeader -Raw
$rtpText = Get-Content -LiteralPath $rtpSource -Raw
$rtpHeaderText = Get-Content -LiteralPath $rtpHeader -Raw
$mirrorParserText = Get-Content -LiteralPath $mirrorParserSource -Raw
$mirrorParserHeaderText = Get-Content -LiteralPath $mirrorParserHeader -Raw
$mirrorText = Get-Content -LiteralPath $mirrorSource -Raw
$raopHeaderText = Get-Content -LiteralPath $raopHeader -Raw
$httpRequestText = Get-Content -LiteralPath $httpRequestSource -Raw
$httpRequestHeaderText = Get-Content -LiteralPath $httpRequestHeader -Raw
$httpdText = Get-Content -LiteralPath $httpdSource -Raw
$fairplayText = Get-Content -LiteralPath $fairplaySource -Raw
$videoRendererText = Get-Content -LiteralPath $videoRendererSource -Raw
$audioRendererText = Get-Content -LiteralPath $audioRendererSource -Raw
$uxplayText = Get-Content -LiteralPath $uxplaySource -Raw

# Crypto must remain a recoverable status API and a reusable streaming API.
Assert-Match $cryptoHeaderText `
    '\bint\s+aes_ctr_(?:reset|encrypt|decrypt|start_fresh_block)\s*\(' `
    "AES-CTR operations expose checked status results"
Assert-Match $cryptoHeaderText `
    '\bint\s+aes_cbc_(?:reset|encrypt|decrypt)\s*\(' `
    "AES-CBC operations expose checked status results"
Assert-Match $cryptoHeaderText `
    '\bint\s+sha_(?:update|final|reset)\s*\(' `
    "SHA operations expose checked status results"
Assert-NoMatch $cryptoText '\b(?:exit|abort|handle_error)\s*\(' `
    "production crypto never terminates the receiver process"

$encryptSlice = Get-SourceSlice $cryptoText `
    "static int aes_encrypt(" "static int aes_decrypt(" "aes_encrypt"
$decryptSlice = Get-SourceSlice $cryptoText `
    "static int aes_decrypt(" "static void aes_destroy(" "aes_decrypt"
$resetSlice = Get-SourceSlice $cryptoText `
    "static int aes_reset(" "// AES CTR" "aes_reset"
Assert-Match $encryptSlice 'EVP_EncryptUpdate\s*\(' `
    "AES encryption uses a reusable EVP update"
Assert-NoMatch $encryptSlice 'EVP_EncryptFinal' `
    "AES encryption does not finalize after every streaming chunk"
Assert-Match $encryptSlice 'out_len_e\s*==\s*in_len' `
    "AES encryption verifies the complete chunk was emitted"
Assert-Match $decryptSlice 'EVP_DecryptUpdate\s*\(' `
    "AES decryption uses a reusable EVP update"
Assert-NoMatch $decryptSlice 'EVP_DecryptFinal' `
    "AES decryption does not finalize after every streaming chunk"
Assert-Match $decryptSlice 'out_len_d\s*==\s*in_len' `
    "AES decryption verifies the complete chunk was emitted"
Assert-InOrder $resetSlice @(
    "EVP_CIPHER_CTX_reset",
    "EVP_CIPHER_CTX_set_padding",
    "ctx->block_offset = 0",
    "return 0"
) "AES reset restores EVP state before wrapper block bookkeeping"

# Catch accidental reintroduction of ignored crypto status calls.  This
# pattern only matches a complete bare C call statement.  Braces and earlier
# semicolons terminate the match, so checked multiline conditions are not
# mistaken for discarded calls merely because a continuation line starts with
# the function name.  Assignments and direct returns are deliberately accepted.
$checkedCryptoSources = @(
    $cryptoText,
    $pairingText,
    $mirrorBufferText,
    $raopBufferText,
    $handlersText
) -join "`n"
$bareCryptoStatusCall = '(?m)^\s*(?:' +
    'aes_(?:ctr|cbc)_(?:reset|encrypt|decrypt|start_fresh_block)|' +
    'sha_(?:update|final|reset)|md5_(?:update|final|reset)|' +
    'gcm_(?:encrypt|decrypt)|x25519_(?:key_get_raw|derive_secret)|' +
    'ed25519_(?:key_get_raw|sign|verify)|get_random_bytes|pk_to_base64' +
    ')\s*\([^;{}]*\)\s*;'
Assert-NoMatch $checkedCryptoSources $bareCryptoStatusCall `
    "security-relevant crypto status results are never discarded"

# NTP and audio worker starts use the same explicit tri-state contract.
Assert-Match $ntpHeaderText `
    ('RAOP_NTP_START_FAILED\s*=\s*-1\s*,\s*' +
     'RAOP_NTP_START_BUSY\s*=\s*0\s*,\s*' +
     'RAOP_NTP_START_OK\s*=\s*1') `
    "NTP start API defines failed, busy, and successful states"
Assert-Match $ntpHeaderText `
    '\bint\s+raop_ntp_start\s*\(' `
    "NTP start result is observable by SETUP"
Assert-Match $rtpHeaderText `
    ('RAOP_RTP_START_FAILED\s*=\s*-1\s*,\s*' +
     'RAOP_RTP_START_BUSY\s*=\s*0\s*,\s*' +
     'RAOP_RTP_START_OK\s*=\s*1') `
    "audio start API defines failed, busy, and successful states"
Assert-Match $rtpHeaderText `
    '\bint\s+raop_rtp_start_audio\s*\(' `
    "audio start result is observable by SETUP"

$ntpStart = Get-SourceSlice $ntpText `
    "raop_ntp_start(raop_ntp_t *raop_ntp" `
    "raop_ntp_wake_unlocked(" "raop_ntp_start"
Assert-InOrder $ntpStart @(
    "worker_lifecycle_can_start_locked",
    "return RAOP_NTP_START_BUSY",
    "raop_ntp_init_socket",
    "return RAOP_NTP_START_FAILED",
    "worker_lifecycle_start_thread_locked",
    "CLOSESOCKET(raop_ntp->tsock)",
    "return RAOP_NTP_START_FAILED",
    "*timing_lport = raop_ntp->timing_lport",
    "return RAOP_NTP_START_OK"
) "NTP publishes its bound port only after socket and thread success"

$audioStart = Get-SourceSlice $rtpText `
    "raop_rtp_start_audio(raop_rtp_t *raop_rtp" `
    "raop_rtp_set_volume(" "raop_rtp_start_audio"
Assert-InOrder $audioStart @(
    "worker_lifecycle_can_start_locked",
    "return RAOP_RTP_START_BUSY",
    "raop_rtp_init_sockets",
    "return RAOP_RTP_START_FAILED",
    "worker_lifecycle_start_thread_locked",
    "CLOSESOCKET(raop_rtp->csock)",
    "CLOSESOCKET(raop_rtp->dsock)",
    "return RAOP_RTP_START_FAILED",
    "*control_lport = raop_rtp->control_lport",
    "*data_lport = raop_rtp->data_lport",
    "return RAOP_RTP_START_OK"
) "audio publishes bound ports only after both sockets and its thread succeed"

# Every supplied SETUP mode must be valid, while a legitimate combined
# key/timing + streams request remains allowed.
$setupHandler = Get-SourceSlice $handlersText `
    "raop_handler_setup(raop_conn_t *conn" `
    "raop_handler_audiomode(raop_conn_t *conn" "raop_handler_setup"
Assert-InOrder $setupHandler @(
    'plist_dict_get_item(req_root_node, "ekey")',
    'plist_dict_get_item(req_root_node, "eiv")',
    'plist_dict_get_item(req_root_node, "streams")',
    "bool has_ekey",
    "bool has_eiv",
    "bool has_streams",
    "bool key_setup",
    "bool stream_setup",
    "(!key_setup && !stream_setup)",
    "raop_handler_setup_error",
    "plist_t res_root_node = plist_new_dict()"
) "SETUP validates supplied modes before response allocation or worker work"
Assert-Match $setupHandler `
    ('key_setup\s*=\s*PLIST_IS_DATA\(req_eiv_node\)\s*&&\s*' +
     'PLIST_IS_DATA\(req_ekey_node\)') `
    "SETUP accepts key mode only with both binary key fields"
Assert-Match $setupHandler `
    'stream_setup\s*=\s*PLIST_IS_ARRAY\(req_streams_node\)' `
    "SETUP accepts stream mode only with an array"
Assert-Match $setupHandler `
    '\(\(has_eiv\s*\|\|\s*has_ekey\)\s*&&\s*!key_setup\)' `
    "SETUP rejects partial or mistyped supplied key fields"
Assert-Match $setupHandler `
    '\(has_streams\s*&&\s*!stream_setup\)' `
    "SETUP rejects a mistyped supplied streams field"
Assert-NoMatch $setupHandler `
    '\bkey_setup\s*\^\s*stream_setup\b' `
    "SETUP does not impose an unsupported exclusive-or on combined mode"

Assert-InOrder $setupHandler @(
    "int ntp_start_result = raop_ntp_start",
    "if (ntp_start_result != RAOP_NTP_START_OK)",
    "raop_rtp_mirror_destroy(new_mirror)",
    "raop_rtp_destroy(new_rtp)",
    "raop_ntp_destroy(new_ntp)",
    "conn->raop_ntp = new_ntp",
    "conn->raop_rtp = new_rtp",
    "conn->raop_rtp_mirror = new_mirror",
    'plist_new_uint(timing_lport)'
) "first SETUP cleans failed timing ownership before publishing the session"
Assert-Match $setupHandler `
    'ntp_start_result\s*==\s*RAOP_NTP_START_BUSY\s*\?\s*409\s*:\s*500' `
    "first SETUP maps NTP busy and failure states explicitly"

Assert-InOrder $setupHandler @(
    "int audio_start_result = conn->raop_rtp",
    "if (audio_start_result != RAOP_RTP_START_OK)",
    "raop_handler_setup_error",
    'logger_log(raop->logger, LOGGER_DEBUG,',
    'plist_new_uint(dport)'
) "stream SETUP checks audio start before advertising its bound ports"
Assert-Match $setupHandler `
    'audio_start_result\s*==\s*RAOP_RTP_START_BUSY\s*\?\s*409\s*:\s*500' `
    "stream SETUP maps duplicate audio and internal start failure explicitly"

# Mirror payload parsing keeps remote lengths bounded and validates a complete
# frame before mutating length prefixes into Annex B start codes.
Assert-Match $mirrorParserHeaderText `
    'MIRROR_VIDEO_PAYLOAD_MAX\s+\(\(size_t\)\s*32U\s*\*\s*1024U\s*\*\s*1024U\)' `
    "mirroring video payloads retain the 32 MiB cap"
Assert-Match $mirrorParserHeaderText `
    'MIRROR_CONFIG_PAYLOAD_MAX\s+\(\(size_t\)\s*256U\s*\*\s*1024U\)' `
    "codec configuration payloads retain the 256 KiB cap"
Assert-Match $mirrorParserHeaderText `
    'MIRROR_REPORT_PLIST_MAX\s+\(\(size_t\)\s*1024U\s*\*\s*1024U\)' `
    "mirroring report plists retain the 1 MiB cap"
Assert-Match $mirrorParserHeaderText `
    'MIRROR_REPORT_TRAILER_SIZE\s+\(\(size_t\)\s*25000U\)' `
    "only the observed bounded report trailer remains allowed"
Assert-Match $mirrorParserHeaderText `
    'MIRROR_CONTROL_PAYLOAD_MAX\s+\(\(size_t\)\s*64U\s*\*\s*1024U\)' `
    "other mirroring control payloads retain the 64 KiB cap"

$cursorTake = Get-SourceSlice $mirrorParserText `
    "mirror_cursor_take(mirror_cursor_t *cursor" `
    "static uint16_t" "mirror_cursor_take"
Assert-InOrder $cursorTake @(
    "cursor->off > cursor->len",
    "len > cursor->len - cursor->off",
    "*span = cursor->data + cursor->off",
    "cursor->off += len"
) "mirror cursor validates subtraction bounds before exposing a span"

$sizeAdd = Get-SourceSlice $mirrorParserText `
    "mirror_size_add(size_t left" `
    "mirror_payload_is_h265(" "mirror_size_add"
Assert-InOrder $sizeAdd @(
    "!result",
    "right > SIZE_MAX - left",
    "*result = left + right"
) "mirroring size addition rejects overflow before calculating the sum"

$nalConvertStart = $mirrorParserText.IndexOf(
    "mirror_convert_nalus(", [StringComparison]::Ordinal)
Assert-True ($nalConvertStart -ge 0) "mirror NAL conversion exists"
$nalConvert = $mirrorParserText.Substring($nalConvertStart)
Assert-InOrder $nalConvert @(
    "Validate the complete frame before changing any length prefix",
    "remaining = payload_size - offset",
    "(size_t) wire_len > remaining",
    "if (count > (size_t) INT_MAX)",
    "offset = 0",
    "memcpy(payload + offset, nal_start_code"
) "NAL conversion completes a read-only validation pass before mutation"

$mirrorThread = Get-SourceSlice $mirrorText `
    "raop_rtp_mirror_thread(void *arg)" `
    "raop_rtp_mirror_init_socket(" "raop_rtp_mirror_thread"
Assert-InOrder $mirrorThread @(
    "uint32_t declared_payload_size = byteutils_get_int(packet, 0)",
    "mirror_payload_size_allowed(packet[4], payload_size)",
    "payload = malloc(payload_size)"
) "mirror transport rejects oversized declared payloads before allocation"
Assert-InOrder $mirrorThread @(
    "if (payload == NULL && ret == 0)",
    "raop_rtp_mirror_close_stream",
    "continue",
    "if (ret == 0)",
    "raop_rtp_mirror_mark_transport_failure",
    "break"
) "header EOF permits a new client while mid-payload EOF resets the session"
Assert-MatchCount $mirrorThread `
    'callbacks\.conn_reset\s*\(raop_rtp_mirror->callbacks\.cls,\s*1\)' `
    1 "mirror transport emits at most one connection reset at thread tail"

# HTTP request limits are applied incrementally and parse failures are removed
# before a request can reach the protocol callback.
Assert-Match $httpRequestHeaderText `
    'HTTP_REQUEST_MAX_URL_BYTES\s+4096U' `
    "request URL cap remains 4096 bytes"
Assert-Match $httpRequestHeaderText `
    'HTTP_REQUEST_MAX_HEADER_FIELDS\s+20U' `
    "request header field cap remains 20"
Assert-Match $httpRequestHeaderText `
    'HTTP_REQUEST_MAX_HEADER_NAME_BYTES\s+64U' `
    "request header name cap remains 64 bytes"
Assert-Match $httpRequestHeaderText `
    'HTTP_REQUEST_MAX_HEADER_VALUE_BYTES\s+1024U' `
    "request header value cap remains 1024 bytes"
Assert-Match $httpRequestHeaderText `
    'HTTP_REQUEST_MAX_BODY_BYTES\s+\(32U\s*\*\s*1024U\s*\*\s*1024U\)' `
    "request body cap remains 32 MiB"

$httpAppend = Get-SourceSlice $httpRequestText `
    "http_request_append(char **target" "on_url(llhttp_t *parser" `
    "http_request_append"
Assert-InOrder $httpAppend @(
    "*target_len > limit",
    "length > limit - *target_len",
    "realloc(*target, *target_len + length + 1U)"
) "HTTP fragmented fields check subtraction bounds before allocation"
$httpHeaderField = Get-SourceSlice $httpRequestText `
    "on_header_field(llhttp_t *parser" `
    "on_header_value(llhttp_t *parser" "on_header_field"
Assert-InOrder $httpHeaderField @(
    "HTTP_REQUEST_MAX_HEADER_FIELDS",
    "request->headers_size += 2",
    "realloc(request->headers"
) "HTTP header count is capped before the pointer array grows"
$httpBody = Get-SourceSlice $httpRequestText `
    "on_body(llhttp_t *parser" `
    "on_headers_complete(llhttp_t *parser" "on_body"
Assert-InOrder $httpBody @(
    "request->datalen > HTTP_REQUEST_MAX_BODY_BYTES",
    "length > HTTP_REQUEST_MAX_BODY_BYTES - request->datalen",
    "realloc(request->data, request->datalen + length)"
) "HTTP body growth checks subtraction bounds before allocation"
$httpDispatch = Get-SourceSlice $httpdText `
    "Parse HTTP request from data read from connection" `
    "const char *data;" "httpd request parse and dispatch"
Assert-InOrder $httpDispatch @(
    "int parse_result = http_request_add_data",
    "parse_result != 0",
    "http_request_has_error(connection->request)",
    "httpd_remove_connection(httpd, connection, 0)",
    "continue",
    "http_request_is_complete(connection->request)",
    "httpd->callbacks.conn_request"
) "HTTP parser errors are dropped before protocol dispatch"

# FairPlay and audioMode handlers validate representation and ownership before
# fixed-offset reads, table indexing, key use, and logging.
$fairplaySetup = Get-SourceSlice $fairplayText `
    "fairplay_setup(fairplay_t *fp" `
    "fairplay_handshake(fairplay_t *fp" "fairplay_setup"
Assert-InOrder $fairplaySetup @(
    "!fp || !req || !res",
    "req[4] != 0x03",
    "req[14] >= 4",
    "int mode = req[14]",
    "reply_message[mode]"
) "FairPlay setup checks pointers, version, and mode before table indexing"
$fairplayHandshake = Get-SourceSlice $fairplayText `
    "fairplay_handshake(fairplay_t *fp" `
    "fairplay_decrypt(fairplay_t *fp" "fairplay_handshake"
Assert-InOrder $fairplayHandshake @(
    "!fp || !req || !res",
    "req[4] != 0x03",
    "memcpy(fp->keymsg, req, 164)",
    "fp->keymsglen = 164"
) "FairPlay handshake validates input before retaining fixed-size key data"
$fairplayDecrypt = Get-SourceSlice $fairplayText `
    "fairplay_decrypt(fairplay_t *fp" `
    "fairplay_destroy(fairplay_t *fp" "fairplay_decrypt"
Assert-InOrder $fairplayDecrypt @(
    "!fp || !input || !output",
    "fp->keymsglen != 164",
    "playfair_decrypt"
) "FairPlay decryption requires a completed 164-byte handshake"

$fpHandler = Get-SourceSlice $handlersText `
    "raop_handler_fpsetup(raop_conn_t *conn" `
    "raop_handler_options(raop_conn_t *conn" "raop_handler_fpsetup"
Assert-InOrder $fpHandler @(
    "!conn->fairplay || !data || (datalen != 16 && datalen != 164)",
    "if (datalen == 16)",
    "fairplay_setup",
    "free(*response_data)",
    "*response_data = NULL",
    "if (datalen == 164)",
    "fairplay_handshake",
    "free(*response_data)",
    "*response_data = NULL"
) "fp-setup enforces exact message sizes and cleans failed replies"

$audioModeHandler = Get-SourceSlice $handlersText `
    "raop_handler_audiomode(raop_conn_t *conn" `
    "raop_handler_feedback(raop_conn_t *conn" "raop_handler_audiomode"
Assert-InOrder $audioModeHandler @(
    "!data || data_len <= 0",
    "PLIST_IS_DICT(req_root_node)",
    "PLIST_IS_STRING(req_audiomode_node)",
    "plist_get_string_val(req_audiomode_node, &audiomode)",
    "if (!audiomode)",
    'audioMode: %s',
    "plist_mem_free(audiomode)",
    "plist_free(req_root_node)"
) "audioMode checks plist types and frees extracted and root ownership"

Assert-InOrder $setupHandler @(
    "bool saw_audio = false",
    "bool saw_mirror = false",
    "Validate the complete request before starting any worker",
    "if (saw_mirror || !PLIST_IS_UINT(stream_id_node))",
    "if (saw_audio)",
    "plist_t res_streams_node = plist_new_array()",
    "raop_rtp_mirror_start",
    "raop_rtp_start_audio"
) "SETUP rejects duplicate streams during a complete validation pass"

# UDP state is accepted only from the negotiated peer, and endpoint pinning
# occurs only after packet length and type checks.
$rtpControl = Get-SourceSlice $rtpText `
    "if (FD_ISSET(raop_rtp->csock, &rfds))" `
    "rtp audio data packets" "RTP control receive"
Assert-InOrder $rtpControl @(
    "packetlen = recvfrom",
    "if (packetlen < 0)",
    "netutils_sockaddr_equal_ip(&saddr, &raop_rtp->remote_saddr)",
    "netutils_sockaddr_get_port(&saddr, &source_port)",
    "netutils_sockaddr_equal_endpoint(&saddr, &raop_rtp->control_saddr)",
    "packetlen < 2",
    "type_c = packet[1]",
    "type_c == 0x56 && packetlen >= 8",
    "memcpy(&raop_rtp->control_saddr, &saddr, saddrlen)",
    "process_control_packet = true"
) "RTP control state pins only a valid negotiated-peer packet"

$rtpData = Get-SourceSlice $rtpText `
    "if (FD_ISSET(raop_rtp->dsock, &rfds))" `
    "Natural exit deliberately leaves join debt" "RTP data receive"
Assert-InOrder $rtpData @(
    "packetlen = recvfrom",
    "if (packetlen < 0)",
    "netutils_sockaddr_equal_ip(&saddr, &raop_rtp->remote_saddr)",
    "packetlen < 2",
    "type_d = packet[1]",
    "type_d != 0x60 || packetlen < 12",
    "netutils_sockaddr_equal_endpoint(&saddr, &data_saddr)",
    "memcpy(&data_saddr, &saddr, saddrlen)",
    "got_remote_data_saddr = true"
) "RTP data endpoint pins only after peer, length, and type validation"

$ntpReceive = Get-SourceSlice $ntpText `
    "response_len = recvfrom" "// Sleep for 3 seconds" "NTP receive"
Assert-InOrder $ntpReceive @(
    "if (response_len < 0)",
    "response_len != 32",
    "netutils_sockaddr_equal_endpoint(&response_saddr",
    "response[0] != 0x80",
    "(response[1] & ~0x80) != 0x53",
    "memcmp(response + 8, request + 24, 8) != 0",
    "MUTEX_LOCK(raop_ntp->sync_params_mutex)",
    "raop_ntp->sync_offset = offset",
    "raop_ntp->client_time_received = true",
    "MUTEX_UNLOCK(raop_ntp->sync_params_mutex)"
) "NTP commits a synchronized sample only after exact peer and origin checks"
$videoOffsetSet = Get-SourceSlice $ntpText `
    "raop_ntp_set_video_arrival_offset(" `
    "raop_ntp_get_video_arrival_offset(" "NTP video offset setter"
Assert-InOrder $videoOffsetSet @(
    "MUTEX_LOCK(raop_ntp->sync_params_mutex)",
    "raop_ntp->video_arrival_offset = *offset",
    "MUTEX_UNLOCK(raop_ntp->sync_params_mutex)"
) "NTP video arrival offset writes use the synchronization mutex"
$videoOffsetGet = Get-SourceSlice $ntpText `
    "raop_ntp_get_video_arrival_offset(" `
    "raop_ntp_parse_remote(" "NTP video offset getter"
Assert-InOrder $videoOffsetGet @(
    "MUTEX_LOCK(raop_ntp->sync_params_mutex)",
    "uint64_t offset = raop_ntp->video_arrival_offset",
    "MUTEX_UNLOCK(raop_ntp->sync_params_mutex)",
    "return offset"
) "NTP video arrival offset reads use the synchronization mutex"

# Appsrc remains non-blocking and unbounded by deliberate policy: dropping an
# arbitrary inter-frame video buffer corrupts decode dependencies, while
# blocking here can stall the same reader that carries control transitions.
Assert-MatchCount $videoRendererText `
    'g_string_new\("appsrc name=video_source ! "\)' `
    1 "video pipeline has one canonical appsrc launch point"
Assert-MatchCount $audioRendererText `
    'g_string_new\("appsrc name=audio_source ! "\)' `
    1 "audio pipeline has one canonical appsrc launch point"
$rendererText = $videoRendererText + "`n" + $audioRendererText
Assert-NoMatch $rendererText `
    '\b(?:max-bytes|max-buffers|max-time|leaky-type|block)\s*=' `
    "renderer appsrc does not introduce unsafe drop or reader-block policy"

$videoSnapshot = Get-SourceSlice $videoRendererText `
    "aeromirror_snapshot_selected_renderer(" `
    "aeromirror_acquire_renderer_for_bus(" "video renderer snapshot"
Assert-InOrder $videoSnapshot @(
    "g_mutex_lock(&renderer_lock)",
    "gst_object_ref(renderer->appsrc)",
    "gst_object_ref(renderer->pipeline)",
    "g_mutex_unlock(&renderer_lock)"
) "video renderer snapshots strong appsrc and pipeline references under lock"
$videoBusAcquire = Get-SourceSlice $videoRendererText `
    "aeromirror_acquire_renderer_for_bus(" `
    "aeromirror_release_renderer_for_bus(" "video bus acquire"
Assert-InOrder $videoBusAcquire @(
    "g_mutex_lock(&renderer_lock)",
    "renderer_type[i]->bus == bus",
    "aeromirror_bus_callback_refs++",
    "gst_object_ref(selected->pipeline)",
    "gst_object_ref(selected->appsrc)",
    "g_mutex_unlock(&renderer_lock)"
) "video bus callback retains the exact bus owner and its GStreamer objects"
$videoBusRelease = Get-SourceSlice $videoRendererText `
    "aeromirror_release_renderer_for_bus(" `
    "static void aeromirror_health_reset(" "video bus release"
Assert-InOrder $videoBusRelease @(
    "g_mutex_lock(&renderer_lock)",
    "aeromirror_bus_callback_refs--",
    "g_cond_broadcast(&renderer_callback_cond)",
    "g_mutex_unlock(&renderer_lock)"
) "video bus callback releases retained renderer lifetime under lock"

$videoRender = Get-SourceSlice $videoRendererText `
    "video_renderer_render_buffer(" `
    "video_renderer_flush(" "video render"
Assert-InOrder $videoRender @(
    "g_mutex_lock(&renderer_lock)",
    "gst_object_ref(renderer->appsrc)",
    "gst_object_ref(renderer->pipeline)",
    "base_time = gst_video_pipeline_base_time",
    "g_mutex_unlock(&renderer_lock)",
    "if (!appsrc || !pipeline)",
    "GstClockTime pts",
    "gst_app_src_push_buffer",
    "gst_object_unref(appsrc)",
    "gst_object_unref(pipeline)"
) "video render retains selected objects before reading clock state and PTS"
$videoResume = Get-SourceSlice $videoRendererText `
    "video_renderer_resume()" "video_renderer_start()" "video resume"
Assert-NoMatch $videoResume 'gst_element_get_state\s*\(' `
    "implicit resume never waits synchronously for a GStreamer state change"
Assert-InOrder $videoResume @(
    "aeromirror_snapshot_selected_renderer",
    "gst_element_set_state",
    "set_result == GST_STATE_CHANGE_FAILURE",
    "gst_object_unref(appsrc)",
    "gst_object_unref(pipeline)"
) "video resume checks immediate failure and releases its strong references"
$videoDestroyInstance = Get-SourceSlice $videoRendererText `
    "video_renderer_destroy_instance(" `
    "video_renderer_destroy()" "video renderer instance destroy"
Assert-InOrder $videoDestroyInstance @(
    "g_mutex_lock(&renderer_lock)",
    "while (renderer->aeromirror_bus_callback_refs > 0)",
    "g_cond_wait(&renderer_callback_cond, &renderer_lock)",
    "g_mutex_unlock(&renderer_lock)",
    "gst_object_unref (renderer->appsrc)",
    "gst_object_unref(renderer->pipeline)",
    "free (renderer)"
) "video destroy waits for mapped bus callbacks before releasing ownership"
$videoDestroy = Get-SourceSlice $videoRendererText `
    "video_renderer_destroy()" `
    "static void get_stream_status_name(" "video renderer destroy"
Assert-InOrder $videoDestroy @(
    "g_mutex_lock(&renderer_lock)",
    "renderer = NULL",
    "destroyed[i] = renderer_type[i]",
    "renderer_type[i] = NULL",
    "g_mutex_unlock(&renderer_lock)",
    "video_renderer_destroy_instance(destroyed[i])"
) "video destroy unpublishes renderer slots before releasing instances"
$chooseCodec = Get-SourceSlice $videoRendererText `
    "video_renderer_choose_codec (" `
    "video_renderer_set_start(" "video renderer codec selection"
Assert-NoMatch $chooseCodec '\bfree\s*\(' `
    "codec selection retains unused renderer structures"
Assert-NoMatch $chooseCodec 'renderer_type\s*\[[^\]]+\]\s*=\s*NULL' `
    "codec selection does not clear retained renderer slots"
Assert-InOrder $chooseCodec @(
    "gst_object_ref(renderer_type[i]->pipeline)",
    "g_mutex_unlock(&renderer_lock)",
    "gst_element_set_state(unused_pipelines[i], GST_STATE_NULL)",
    "gst_object_unref(unused_pipelines[i])"
) "codec selection stops unused pipelines through temporary strong references"

$audioStop = Get-SourceSlice $audioRendererText `
    "audio_renderer_stop()" "static void get_renderer_type(" "audio stop"
Assert-InOrder $audioStop @(
    "g_mutex_lock(&audio_renderer_lock)",
    "gst_object_ref(renderer->appsrc)",
    "gst_object_ref(renderer->pipeline)",
    "renderer = NULL",
    "g_mutex_unlock(&audio_renderer_lock)",
    "gst_app_src_end_of_stream",
    "gst_element_set_state",
    "gst_object_unref(appsrc)",
    "gst_object_unref(pipeline)"
) "audio stop snapshots strong references before unpublishing the renderer"
$audioDestroy = Get-SourceSlice $audioRendererText `
    "audio_renderer_destroy()" `
    "gstreamer_audio_pipeline_bus_callback(" "audio destroy"
Assert-InOrder $audioDestroy @(
    "audio_renderer_stop()",
    "g_mutex_lock(&audio_renderer_lock)",
    "destroyed[i] = renderer_type[i]",
    "renderer_type[i] = NULL",
    "g_mutex_unlock(&audio_renderer_lock)",
    "gst_object_unref(destroyed[i]->bus)",
    "gst_object_unref(destroyed[i]->pipeline)",
    "free(destroyed[i])"
) "audio destroy unpublishes slots under the same lock before releasing them"
$audioBus = Get-SourceSlice $audioRendererText `
    "gstreamer_audio_pipeline_bus_callback(" `
    "audio_renderer_listen(" "audio bus callback"
Assert-InOrder $audioBus @(
    "g_mutex_lock(&audio_renderer_lock)",
    "message_renderer->bus == bus",
    "gst_object_ref(message_renderer->appsrc)",
    "gst_object_ref(message_renderer->pipeline)",
    "g_mutex_unlock(&audio_renderer_lock)",
    "if (!message_pipeline)",
    "gst_object_unref(message_appsrc)",
    "gst_object_unref(message_pipeline)"
) "audio bus callback maps the exact bus and retains objects under lock"

# A valid video access unit resumes a paused pipeline even if the iPhone omits
# the usual codec-option resume signal.  The action is durable in diagnostics.
Assert-Match $raopHeaderText `
    'MIRROR_PACKET_ACTION_IMPLICIT_RESUME\s*=\s*3' `
    "mirroring diagnostics expose the implicit-resume action"
$type0Start = $mirrorThread.IndexOf("case  0x00:", [StringComparison]::Ordinal)
$type0End = $mirrorThread.IndexOf("case 0x01:", $type0Start,
                                  [StringComparison]::Ordinal)
Assert-True ($type0Start -ge 0 -and $type0End -gt $type0Start) `
    "mirror type-0 handler slice exists"
$type0Handler = $mirrorThread.Substring($type0Start, $type0End - $type0Start)
Assert-InOrder $type0Handler @(
    "mirror_buffer_decrypt",
    "mirror_convert_nalus",
    "if (video_stream_suspended)",
    "video_stream_suspended = false",
    "type0_action = MIRROR_PACKET_ACTION_IMPLICIT_RESUME",
    "AEROMIRROR_VIDEO_IMPLICIT_RESUME reason=valid-type0",
    "callbacks.video_resume",
    "packet[6], type0_action",
    "callbacks.video_process"
) "implicit resume occurs only after decrypt and complete NAL validation"
Assert-MatchCount $type0Handler `
    'packet\[6\],\s*type0_action' `
    1 "the type-0 diagnostic records the implicit action exactly once"
Assert-InOrder $uxplayText @(
    "static std::atomic<uint64_t> aeromirror_implicit_resume_actions(0)",
    "event->action == MIRROR_PACKET_ACTION_IMPLICIT_RESUME",
    "aeromirror_implicit_resume_actions.fetch_add(1)",
    "aeromirror_implicit_resume_actions.load()",
    'implicit_resume=%',
    "implicit_resume_actions"
) "implicit resume has a durable counter and health-log field"

Write-Host "Native core source contracts passed for parsers, crypto, transport, SETUP, and renderers."

# Compile the exact production crypto.c and execute a bounded, positive-only
# NIST vector.  No malformed protocol, parser, or network inputs are used.
$originalPath = $env:PATH
$compilerDirectory = Split-Path -Parent $compiler
$env:PATH = $compilerDirectory + [IO.Path]::PathSeparator + $originalPath
$compilerInfo = & $compiler --version
Assert-True ($LASTEXITCODE -eq 0 -and @($compilerInfo).Count -gt 0) `
    "native compiler starts"
$compilerBanner = [string]@($compilerInfo)[0]

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) (
    "aeromirror-native-core-contracts-" + [Guid]::NewGuid().ToString("N"))
$executable = Join-Path $temporaryRoot "native-crypto-happy-path.exe"

try {
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    $arguments = @(
        "-std=c11",
        "-O2",
        "-Wall",
        "-Wextra",
        "-Werror",
        "-Wpedantic",
        ("-I" + (Join-Path $libRoot "lib")),
        ("-I" + $opensslInclude),
        $cryptoSource,
        $harnessSource,
        $cryptoImportLibrary,
        "-o",
        $executable
    )
    & $compiler @arguments
    Assert-True ($LASTEXITCODE -eq 0) `
        "exact production crypto.c and happy-path harness compile cleanly"
    Assert-True (Test-Path -LiteralPath $executable -PathType Leaf) `
        "native crypto happy-path executable is produced"

    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $executable
    $start.WorkingDirectory = $temporaryRoot
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    try {
        Assert-True ($process.Start()) "native crypto happy-path harness starts"
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)
        if (-not $completed) {
            try { $process.Kill() } catch {}
            try { $process.WaitForExit(5000) | Out-Null } catch {}
            throw "FAILED: native crypto harness exceeded $TimeoutSeconds seconds"
        }
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        if (-not [string]::IsNullOrWhiteSpace($stdout)) {
            Write-Host $stdout.TrimEnd()
        }
        if (-not [string]::IsNullOrWhiteSpace($stderr)) {
            Write-Host $stderr.TrimEnd()
        }
        Assert-True ($process.ExitCode -eq 0) `
            "native crypto happy-path harness exits successfully"
        Assert-True ($stdout.Contains(
            "Native production crypto happy-path checks passed")) `
            "native crypto harness emits its completion marker"
    }
    finally {
        $process.Dispose()
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
    $env:PATH = $originalPath
}

Write-Host (
    "Native core contracts passed against exact production crypto using " +
    $compilerBanner + ".")
exit 0
