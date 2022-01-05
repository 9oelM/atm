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

atm-unique-and-randomize-api-wordlist.sh

uniqs duplicate endpoints and randomizes ids in an api wordlist.
the wordlist should contain endpoints, such as:

/admin/groups/12176189
/admin/network/60715597/status

this script helps remove duplicate endpoints. Removing duplicates is not simple because
there are different ids in endpoints, sometimes. This means a simple \`sort -u\` won't be able
to remove duplicated endpoints that just have different ids in their path. This script just
does exactly that. It removes duplicates including those having different ids in their paths.  

example: cat admin-api-wordlist.txt | atm-unique-and-randomize-api-wordlist.sh -o clean.txt

usage:
-o [required] [string] path to output file.
-h help
"

function reject_with_message_and_usage() {
    msg="$1"
    echo "$1"
    echo "${usage}"
    echo "$1"
    exit
}

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

stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    reject_with_message_and_usage "[!] No stdin detected. Pipe input into this script."
fi

export ID_PATH_REGEX="\/[0-9]\+\/"
export ID_PATH_REGEX_AT_THE_END="\/[0-9]\+$"
export TEMP_REPLACED_MARK="%REPLACED%"

function replace_with_temp_replaced_mark() {
    line="$1"
    random_number=$(shuf -i 1-100000 -n 1)
    wordlist_with_random_range_of_ids=$(echo "${line}" | sed -e "s/${TEMP_REPLACED_MARK}/\/${random_number}\//g")
    echo "${wordlist_with_random_range_of_ids}"
}
function replace_with_temp_replaced_mark_without_trailing_slash() {
    line="$1"
    random_number=$(shuf -i 1-100000 -n 1)
    wordlist_with_random_range_of_ids=$(echo "${line}" | sed -e "s/${TEMP_REPLACED_MARK}/\/${random_number}/g")
    echo "${wordlist_with_random_range_of_ids}"
}
export -f replace_with_temp_replaced_mark
export -f replace_with_temp_replaced_mark_without_trailing_slash

function remove_duplicate_and_randomize_ids_in_endpoints() {
    unique_wordlist_with_temp_replaced_marks=$(echo "${stdin}" | sed -e "s/${ID_PATH_REGEX}/${TEMP_REPLACED_MARK}/g" | sort -u)
    
    # /admin/67297953/recommend --> /admin/%REPLACED%/recommend
    numbers_in_between_slashes_replaced=$(echo "${unique_wordlist_with_temp_replaced_marks}" | xargs -P 1000 -I {} bash -c 'replace_with_temp_replaced_mark "$@"' _ {})
    
    # /admin/recommend/67297953 --> /admin/recommend/%REPLACED%
    unique_wordlist_with_temp_replaced_marks_on_trailing_numbers=$(echo "${numbers_in_between_slashes_replaced}" | sed -e "s/${ID_PATH_REGEX_AT_THE_END}/${TEMP_REPLACED_MARK}/g" | sort -u)

    echo "${unique_wordlist_with_temp_replaced_marks_on_trailing_numbers}" | xargs -P 1000 -I {} bash -c 'replace_with_temp_replaced_mark_without_trailing_slash "$@"' _ {} | tee "${OUTPUT_FILE_PATH}"
}

[ -f "${OUTPUT_FILE_PATH}" ] && reject_with_message_and_usage "${OUTPUT_FILE_PATH} already exists. Try different path." && exit 1
[ -z "${OUTPUT_FILE_PATH}" ] && reject_with_message_and_usage "-o option needs to be supplied." && exit 1

[ ! -z "${OUTPUT_FILE_PATH}" ] && [ ! -f "${OUTPUT_FILE_PATH}" ] && remove_duplicate_and_randomize_ids_in_endpoints