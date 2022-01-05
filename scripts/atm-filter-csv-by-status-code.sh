#!/bin/bash

UNIQ_COUNT_THRESHOLD="50"
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

atm-filter-csv-by-status-code.sh

outputs rows from a csv file that match the status code.

IMPORTANT:
stdin should contain the column 'status_code' and should be in csv format.

example:
cat processed-ffuf-output.csv | atm-filter-csv-by-status-code.sh -s 200

usage:
-s [required] [string] status code to match.
                       example: 200
                       example 2: 30% (matches 30*)
-o [required] [string] file name as an output from this script in csv format.
-h help
"

while getopts s:h: flag; do
    case "${flag}" in
    s)
        STATUS_CODE=${OPTARG}
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


declare -a all_commands=("csvq")
all_commands_length=${#array[@]}

for i in ${!all_commands[@]}; do
    if ! command -v "${all_commands[i]}" >"/dev/null"; then
        echo "[!] Command ${all_commands[i]} does not exist. You need to install it first. View README.md for installation instructions."
        exit
    fi
done

if [ -z "${STATUS_CODE}" ]; then
    echo "[!] -s option: \"${STATUS_CODE}\" does not exist. Please check again."
    echo "${usage}"
    echo "[!] -s option: \"${STATUS_CODE}\" does not exist. Please check again."
    exit
fi

stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input into this script."
    echo "${usage}"
    echo "[!] No stdin detected. Pipe input into this script."
    exit
fi

echo -n "${stdin}" | csvq -f CSV "select * where status_code LIKE \"${STATUS_CODE}\"" 