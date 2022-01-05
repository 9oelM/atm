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

atm-find-working-urls.sh

hits urls with httpx and filters out those that come back with any of:
- context deadline exceeded
- connection reset by peer
- no address found for host

note that it DOES NOT look at status codes! it only filters out these messages but it usually tends to be working correctly.

example:
cat urls.txt | atm-find-working-urls.sh -t 15

usage:
-o [required] string output file path
-t [optional] int number of threads for httpx request (default 50)
-r [optional] 0|1 remove CloudFlare-hosted domains from the output.
              This option may be weird, but it is sometimes necessary to omit them
              because CloudFlare will block you after few bruteforces, for example.
              (default 0)
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
    echo "    Example: cat myurls.txt | atm-find-working-urls.sh [args]"
    exit
fi

THREADS=50
REMOVE_CLOUDFLARE=0
while getopts t:o:r:h: flag; do
    case "${flag}" in
    t)
        THREADS=${OPTARG}
        ;;
    o)
        OUTPUT_FILE_PATH=${OPTARG}
        ;;
    r)
        REMOVE_CLOUDFLARE=${OPTARG}
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

[ -f "${OUTPUT_FILE_PATH}" ] && printf "${usage}" && echo "[!] File ${OUTPUT_FILE_PATH} already exists. Please try again." && printf "${usage}" && exit 
[ -z "${OUTPUT_FILE_PATH}" ] && printf "${usage}" && echo "[!] -o option is missing. Please try again." && printf "${usage}" && exit 

RAND_STR=$(openssl rand -hex 12)
TMP_DIR=".tmp-${RAND_STR}"
mkdir "./${TMP_DIR}"

function cleanup {
  echo "[+] Removing "${TMP_DIR}" before exit"
  rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

echo "${stdin}" | httpx -t "${THREADS}" -tech-detect -sc -server -cl -title -location -method -cdn -probe -csv -o "./${TMP_DIR}/all.httpx.csv"

# will get overwritten if remove cloudflare option is true
cat "./${TMP_DIR}/all.httpx.csv" > "./${TMP_DIR}/all.processed.httpx.csv"
# remove cloudflare
[ "${REMOVE_CLOUDFLARE}" != "0" ] && (cat "./${TMP_DIR}/all.httpx.csv" | grep -v -i -e cloudflare > "./${TMP_DIR}/all.processed.httpx.csv")

# filter out invalid urls
cat "./${TMP_DIR}/all.processed.httpx.csv" | grep -v -i -e "context deadline exceeded" -e "connection reset by peer" -e "no address found for host" >  "./${TMP_DIR}/all.working.httpx.csv"

# outputs http://first.com\nhttps://second.com ...
csvq --without-header -f FIXED "select url from \`./${TMP_DIR}/all.working.httpx.csv\`" > "./${TMP_DIR}/all.working.urls.txt"  

# remove whitepsaces produced from csvq (except newline)
cat "./${TMP_DIR}/all.working.urls.txt" | awk '{$1=$1};1' > "./${TMP_DIR}/urls.txt" 

cp "./${TMP_DIR}/urls.txt" "${OUTPUT_FILE_PATH}"
