#!/bin/bash
CRLF_INJECTION_HEADER="X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123"

# @todo introduce proper shell unit test framework
function is_vulnerable_to_crlf_injection() {
    headers="$1"
    CRLF_INJECTION_HEADER="$2"
    local -n is_vulnerable="$3"
    is_vulnerable=0
    if [[ ! -z $(echo "${headers}" | sed -e 's/^[ \t]*//' | grep -E "^$CRLF_INJECTION_HEADER*") ]]; then
        is_vulnerable=1
    fi
}

VULNERABLE_HEADERS_1="HTTP/1.1 301 Moved Permanently
Content-Type: text/html
Content-Length: 178
Server: nginx
Location: http://example.com/abc/%0D
X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=7200
Expires: Mon, 22 Nov 2021 04:41:40 GMT
Cache-Control: max-age=0, no-cache
Pragma: no-cache
Date: Mon, 22 Nov 2021 04:41:40 GMT
Connection: keep-alive"

is_vulnerable_to_crlf_injection "${VULNERABLE_HEADERS_1}" "${CRLF_INJECTION_HEADER}" vulnerable_headers_1_result
echo "${vulnerable_headers_1_result}"

VULNERABLE_HEADERS_2="HTTP/1.1 301 Moved Permanently
Content-Type: text/html
Content-Length: 178
Server: nginx
Location: http://example.com/abc/%0D
    X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=7200
Expires: Mon, 22 Nov 2021 04:41:40 GMT
Cache-Control: max-age=0, no-cache
Pragma: no-cache
Date: Mon, 22 Nov 2021 04:41:40 GMT
Connection: keep-alive"

is_vulnerable_to_crlf_injection "${VULNERABLE_HEADERS_2}" "${CRLF_INJECTION_HEADER}" vulnerable_headers_2_result
echo "${vulnerable_headers_2_result}"

VULNERABLE_HEADERS_3="HTTP/1.1 301 Moved Permanently
Content-Type: text/html
Content-Length: 178
Server: nginx
Location: http://example.com/abc/%0D

    X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=7200
Expires: Mon, 22 Nov 2021 04:41:40 GMT
Cache-Control: max-age=0, no-cache
Pragma: no-cache
Date: Mon, 22 Nov 2021 04:41:40 GMT
Connection: keep-alive"

is_vulnerable_to_crlf_injection "${VULNERABLE_HEADERS_3}" "${CRLF_INJECTION_HEADER}" vulnerable_headers_3_result
echo "${vulnerable_headers_3_result}"

NOT_VULNERABLE_HEADER_1="HTTP/1.1 301 Moved Permanently
Content-Type: text/html
Content-Length: 178
Server: nginx
Location: http://example.com/abc/%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=7200
Expires: Mon, 22 Nov 2021 04:41:40 GMT
Cache-Control: max-age=0, no-cache
Pragma: no-cache
Date: Mon, 22 Nov 2021 04:41:40 GMT
Connection: keep-alive"

is_vulnerable_to_crlf_injection "${NOT_VULNERABLE_HEADER_1}" "${CRLF_INJECTION_HEADER}" not_vulnerable_headers_1_result
echo "${not_vulnerable_headers_1_result}"

NOT_VULNERABLE_HEADER_1="HTTP/1.1 301 Moved Permanently
Content-Type: text/html
Content-Length: 178
Server: nginx
Location: http://example.com/abc/\nX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=7200
Expires: Mon, 22 Nov 2021 04:41:40 GMT
Cache-Control: max-age=0, no-cache
Pragma: no-cache
Date: Mon, 22 Nov 2021 04:41:40 GMT
Connection: keep-alive"

is_vulnerable_to_crlf_injection "${NOT_VULNERABLE_HEADER_1}" "${CRLF_INJECTION_HEADER}" not_vulnerable_headers_1_result
echo "${not_vulnerable_headers_1_result}"