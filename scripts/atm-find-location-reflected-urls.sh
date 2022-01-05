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

atm-find-location-reflected-urls.sh.sh

hits urls with httpx and filters out those that come back reflected response. for example: an URL that returns 

HTTP/1.1 301 Moved Permanently 
Location: https://example.com/sth/ABC

to a GET request to https://example.com/ABC

will be included in the output of this shell script. Therefore, this script can mainly be used to get URLs potentially vulnerable to CRLF injection.

example:
cat domains.txt | atm-find-location-reflected-urls.sh -t 15

usage:
-o [required] string output file path
-t [optional] int number of threads for httpx request (default 50)

warning:
The list of URLs piped into this script should NOT end with trailing slashes.
"

declare -a all_commands=("csvq" "httpx")
all_commands_length=${#array[@]}

for i in ${!all_commands[@]}; do
    if ! command -v "${all_commands[i]}" >"/dev/null"; then
        echo "[!] Command ${all_commands[i]} does not exist. You need to install it first. View README.md for installation instructions."
        exit
    fi
done

stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input into this script."
    echo "[!] Note that the domains need to end WITHOUT trailing slashes."
    echo "    Example: cat mydomains.txt | atm-get-location-reflected-domains.sh [args]"

    printf "${usage}"

    echo "[!] No stdin detected. Pipe input into this script."
    echo "[!] Note that the domains need to end WITHOUT trailing slashes."
    echo "    Example: cat mydomains.txt | atm-get-location-reflected-domains.sh [args]"
    exit
fi

THREADS=50
while getopts t:o:h: flag; do
    case "${flag}" in
    t)
        THREADS=${OPTARG}
        ;;
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

[ -f "${OUTPUT_FILE_PATH}" ] && echo "[!] File ${OUTPUT_FILE_PATH} already exists. Please try again." && printf "${usage}"  && echo "[!] File ${OUTPUT_FILE_PATH} already exists. Please try again." && exit 
[ -z "${OUTPUT_FILE_PATH}" ] && echo "[!] -o option is not supplied. Please try again." && printf "${usage}" && echo "[!] -o option is not supplied. Please try again." && exit

RAND_STR=$(openssl rand -hex 12)
TMP_DIR=".tmp-${RAND_STR}"
mkdir "./${TMP_DIR}"

function cleanup {
  echo "[+] Removing "${TMP_DIR}" before exit"
  rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

# stdin contains list of URLs to be tested against. It should end WITHOUT a trailing slash
# get domains that have a reflected response (either in response header or body)
# don't use `while read line` because it's so slow
# add payload to each line of the file
echo "${stdin}" | awk '{print $0"/ABC123ABC123ABC123?ABC123ABC123ABC123=ABC123ABC123ABC123/"}' | awk NF > "./${TMP_DIR}/urls_with_payload.txt"

# remove empty lines if any first
# run requests
grep "\S" "./${TMP_DIR}/urls_with_payload.txt" | httpx -t "${THREADS}" -location -o "./${TMP_DIR}/location_header_test.csv" -csv

# get all urls where location header has the reflected test string
# if you just want to know which responses have Location: header, then simply use this command: csvq -f FIXED 'select url from `location-header-test.csv` where location IS NOT NULL' | awk '{$1=$1};1'
# csvq outputs with trailining whitespaces in each line, so remove that with awk
csvq --without-header -f FIXED "select url from \`./${TMP_DIR}/location_header_test.csv\` where location like \"%ABC123ABC123ABC123%\"" | awk '{$1=$1};1' > "./${TMP_DIR}/result.txt"

cp "./${TMP_DIR}/result.txt" "${OUTPUT_FILE_PATH}"