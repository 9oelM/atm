#!/bin/bash

PAGE_SIZE="1"
ONLY_IPS="1"
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

atm-search-binaryedge.sh

sends a simple binaryedge search query and returns the list of IPs from the result.

IMPORTANT: you need to save your binaryedge API key in $HOME/.atm/binaryedge.key. Just copy and paste your binaryedge api key there. Otherwise, this script won't work.

example:
echo \"kubernetes\" | atm-search-binaryedge.sh

usage:
-o [optional] [string] path to output file. It will contain the raw response from the API.
-s [optional] [int, 0 < n <= 1000 ]expected size of the response. a size of 1 equals to 20 results. max. 1000 possible. (20000 results) (default: ${PAGE_SIZE})
-i [optional] [0|1] whether to get only ips. (default: ${ONLY_IPS})
-h help
"
declare -a all_commands=("curl" "jq")
all_commands_length=${#array[@]}

for i in ${!all_commands[@]}; do
    if ! command -v "${all_commands[i]}" >"/dev/null"; then
        echo "[!] Command ${all_commands[i]} does not exist. You need to install it first. View README.md for installation instructions."
        exit
    fi
done

while getopts o:h:s: flag; do
    case "${flag}" in
    o)
        OUTPUT_FILE_PATH=${OPTARG}
        ;;
    s)
        PAGE_SIZE=${OPTARG}
        ;;
    i)
        ONLY_IPS=${OPTARG}
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

stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input into this script."
    echo "${usage}"
    echo "[!] No stdin detected. Pipe input into this script."
    exit
fi

if [ -f "${OUTPUT_FILE_PATH}" ]; then
    echo "[!] ${OUTPUT_FILE_PATH} already exists. Try different file path"
    echo "${usage}"
    echo "[!] ${OUTPUT_FILE_PATH} already exists. Try different file path"
    exit
fi

if [ ! -f "$HOME/.atm/binaryedge.key" ]; then
    echo "[!] ~/.atm/binaryedge.key does not exist. Please create the file and put your API key in there"
    echo "${usage}"
    echo "[!] ~/.atm/binaryedge.key does not exist. Please create the file and put your API key in there"
    exit
fi

BINARYEDGE_API_KEY=$(cat "$HOME/.atm/binaryedge.key" | sed -e 's/\s//g' | awk NF)

if [ -z "${BINARYEDGE_API_KEY}" ]; then
    echo "[!] ~/.atm/binaryedge.key exists, but does not contain anything. Please put your API key in there"
    echo "${usage}"
    echo "[!] ~/.atm/binaryedge.key exists, but does not contain anything. Please put your API key in there"
    exit
fi

if [ "${ONLY_IPS}" != "1" ] && [ "${ONLY_IPS}" != "0" ]; then
    echo "[!] -i option should be either 1 or 0"
    echo "${usage}"
    echo "[!] -i option should be either 1 or 0"
    exit
fi

encoded_query=$(jq -rn --arg x "${stdin}" '$x|@uri')
# outputs something like {"query":"myquery","page":1,"pagePAGE_SIZE":20,"total":382,"events":[{"ip":"34.126.118.154","port":80,"protocol":"tcp"},{"ip":"116.62.144.68","port":80,"protocol":"tcp"},{"ip":"34.107.27.170","port":80,"protocol":"tcp"},{"ip":"81.68.175.244","port":80,"protocol":"tcp"},{"ip":"114.67.236.232","port":80,"protocol":"tcp"}, ...

if [ -z "${OUTPUT_FILE_PATH}" ]; then
    search_result=$(curl "https://api.binaryedge.io/v2/query/search?query=${encoded_query}&page=${PAGE_SIZE}&only_ips=${ONLY_IPS}" -H "X-Key: ${BINARYEDGE_API_KEY}")
else
    search_result=$(curl "https://api.binaryedge.io/v2/query/search?query=${encoded_query}&page=${PAGE_SIZE}&only_ips=${ONLY_IPS}" -H "X-Key: ${BINARYEDGE_API_KEY}" -o "${OUTPUT_FILE_PATH}")
fi

only_ips=$(echo "${search_result}" | awk NF | jq '.events' | jq -r '.[] | .ip + ":" + (.port|tostring)')

echo "${only_ips}"

