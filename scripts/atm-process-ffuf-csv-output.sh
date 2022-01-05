#!/bin/bash

UNIQ_COUNT_THRESHOLD="15"
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

atm-process-ffuf-csv-output.sh

processes csv output from atm-run-preliminary-ffuf.sh and gives only requests that might be interesting

IMPORTANT:
this script should serve as a processor of prelimiary scout on a target, enumerating all subdomains with a basic wordlist, like this:

ffuf -t 100 -w subdomains.txt:DOMAIN -w /usr/share/wordlists/seclists/Discovery/Web-Content/big.txt:PATHNAME -u DOMAIN/WORDLIST -o output.csv -of csv

this script will then process the output from ffuf and will give a statistics about uniqueness of each content length per identifier you choose.
for example, in the ffuf command above, the identifer could be DOMAIN.

during the processing, it this script will generate another csv file looking like this:

count,domain,content_length,status_code
1,somesubdomain.example.com:443,204,403
1,somesubdomain.example.com:443,9920,403
92241,somesubdomain.example.com:443,8011,403

we can see that a request to DOMAIN with content_length of 204 and 9920 should be worth looking at, because those combinations happen only once per each,
which means there might be something reacting differently.

anyway, to put things simply, this script outputs URLs that seem to be interesting from ffuf output.

example:
atm-process-ffuf-csv-output.sh -f path-to-ffuf-output.csv -o processed.csv

usage:
-f [required] [string] path to ffuf output as csv. 
-o [required] [string] file name as an output from this script in csv format.
-u [optional] [int] uniq_count threshold. (default: ${UNIQ_COUNT_THRESHOLD}) 
-h help
"

while getopts f:o:u:h: flag; do
    case "${flag}" in
    f)
        FFUF_OUTPUT_FILE_CSV=${OPTARG}
        ;;
    o)
        OUTPUT_FILE_PATH=${OPTARG}
        ;;
    u)
        UNIQ_COUNT_THRESHOLD=${OPTARG}
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


declare -a all_commands=("mlr" "xsv" "csvq" "openssl" "sort" "uniq")
all_commands_length=${#array[@]}

for i in ${!all_commands[@]}; do
    if ! command -v "${all_commands[i]}" >"/dev/null"; then
        echo "[!] Command ${all_commands[i]} does not exist. You need to install it first. View README.md for installation instructions."
        exit
    fi
done

if [ ! -f "${FFUF_OUTPUT_FILE_CSV}" ]; then
    echo "[!] -f option: \"${FFUF_OUTPUT_FILE_CSV}\" does not exist. Please check again."
    echo "${usage}"
    echo "[!] -f option: \"${FFUF_OUTPUT_FILE_CSV}\" does not exist. Please check again."
    exit
fi

if [ -z "${OUTPUT_FILE_PATH}" ]; then
    echo "[!] -o option: \"${OUTPUT_FILE_PATH}\" does not exist. Please check again."
    echo "${usage}"
    echo "[!] -o option: \"${OUTPUT_FILE_PATH}\" does not exist. Please check again."
    exit
fi

if [ -f "${OUTPUT_FILE_PATH}" ]; then
    echo "[!] -o option: \"${OUTPUT_FILE_PATH}\" already exists. Please specify a file name that does not exist yet."
    echo "${usage}"
    echo "[!] -o option: \"${OUTPUT_FILE_PATH}\" already exists. Please specify a file name that does not exist yet."
    exit
fi

echo "

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

atm-process-ffuf-csv-output.sh

[+] Starting...
"
# outputs something like
# domain,content_length,status_code
# somesubdomain.example.com:443,204,403
# somesubdomain.example.com:443,8011,403
# somesubdomain.example.com:443,9920,403
echo "[+] Running xsv select"
output_csv=$(xsv select "domain,content_length,status_code" "${FFUF_OUTPUT_FILE_CSV}")

# outputs something like
# count,domain,content_length,status_code
# 1,somesubdomain.example.com:443,204,403
# 92241,somesubdomain.example.com:443,8011,403
# 3,somesubdomain.example.com:443,9920,403
output_sorted_by_unique_count_csv=$(echo -n "${output_csv}" | sed -n '1d;p' | sort | uniq -c)
output_sorted_by_unique_count_csv_header=$(echo -n "${output_csv}" | head -n1)

output_sorted_by_unique_count_in_csv=$(echo -n "${output_sorted_by_unique_count_csv}" | sed -e 's/^ *//g; s/ /\,/;')
# by now it should be something likeq
# uniq_count,domain,content_length,status_code
# 1,somesubdomain.example.com:443,204,403
# 3,somesubdomain.example.com:443,9920,403
# 92241,somesubdomain.example.com:443,8011,403
output_sorted_by_unique_count_in_csv=$(echo "${output_sorted_by_unique_count_in_csv}" | sed -e "1 i\\uniq_count,${output_sorted_by_unique_count_csv_header}")

output_sorted_by_unique_count_in_csv_file=".tmp-atm-$(openssl rand -hex 12).csv"
function cleanup {
  echo "[+] Removing "${output_sorted_by_unique_count_in_csv_file}" before exit"
  rm -rf "${output_sorted_by_unique_count_in_csv_file}" 2>/dev/null
}

trap cleanup EXIT
echo "[+] Running mlr filter"
echo -n "${output_sorted_by_unique_count_in_csv}" | mlr --csv filter "\$uniq_count < ${UNIQ_COUNT_THRESHOLD}" | tee "${output_sorted_by_unique_count_in_csv_file}" > /dev/null

echo "[+] Starting xsv join operation. May take up some CPU/Memory and some time."
# outputs something like:
# url,status_code,content_length
# https://a.example.com:443/favicon.ico,200,154149
# https://b.example.com:443/feed,200,61233
# http://b.example.com:80/WEB-INF,403,33073
# http://b.example.com:80/cgi-bin/,403,33073

# using xsv for a huge performance win. if csvq is used, it will take a LOT of memory
xsv join --no-case content_length,status_code,domain "${output_sorted_by_unique_count_in_csv_file}" content_length,status_code,domain "${FFUF_OUTPUT_FILE_CSV}" | xsv select url,status_code,content_length | mlr --csv sort -f status_code,content_length | tee "${OUTPUT_FILE_PATH}"
echo "[+] Done"
