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

atm-monkeypath-ffuf-csv-output.sh

ffuf has a bug where it mixes up csv columns for some reason: https://github.com/ffuf/ffuf/issues/502. This script fixes the output after ffuf is done.
This script is preconfigured to consume output from atm-run-preliminary-ffuf.sh. 
If you are using it for other purposes and you have different column names in your csv, you should tweak the column names 

example:
atm-monkeypath-ffuf-csv-output.sh -i ffufoutputneedsmonkeypath.csv -o aftermonkeypath.csv

usage:
-i [required] [string] input file path in csv.
-o [required] [string] output file path in csv.
-h help
"

while getopts i:o:h: flag; do
    case "${flag}" in
    i)
        INPUT_FILE_PATH=${OPTARG}
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


declare -a all_commands=("unfurl" "csvq")
all_commands_length=${#array[@]}

for i in ${!all_commands[@]}; do
    if ! command -v "${all_commands[i]}" >"/dev/null"; then
        echo "[!] Command ${all_commands[i]} does not exist. You need to install it first. View README.md for installation instructions."
        exit
    fi
done


if [ ! -f "${INPUT_FILE_PATH}" ]; then
    echo "[!] -i option: \"${INPUT_FILE_PATH}\" file does not exist. Please check again."
    echo "${usage}"
    echo "[!] -i option: \"${INPUT_FILE_PATH}\" file does not exist. Please check again."
    exit
fi


if [ -f "${OUTPUT_FILE_PATH}" ]; then
    echo "[!] -o option: \"${OUTPUT_FILE_PATH}\" already exists. Please check again."
    echo "${usage}"
    echo "[!] -o option: \"${OUTPUT_FILE_PATH}\" already exists. Please check again."
    exit
fi


RAND_STR_2=$(openssl rand -hex 12)
TMP_DOMAIN_COLUMN=".tmp-atm-${RAND_STR_2}.txt"
RAND_STR_3=$(openssl rand -hex 12)
TMP_PATHNAME_COLUMN=".tmp-atm-${RAND_STR_3}.txt"

function cleanup {
  echo "[+] Removing tmp files before exit"
  rm -rf "${TMP_DOMAIN_COLUMN}" 2>/dev/null
  rm -rf "${TMP_PATHNAME_COLUMN}" 2>/dev/null
}

trap cleanup EXIT

#################
# ffuf monkeypatch start
echo "[+] Monkeypatch starting. This script should take some time."
urls=$(csvq -N -f FIXED "select url from \`${INPUT_FILE_PATH}\`")

echo "[+] Runing unfurl"
echo -n "${urls}" | sed -e 's/\s//g' | unfurl format %s://%d | awk NF > "${TMP_DOMAIN_COLUMN}"
echo -n "${urls}" | sed -e 's/\s//g' | unfurl format %p | sed -e 's/\///' | awk NF > "${TMP_PATHNAME_COLUMN}"

echo "[+] Altering tables"
# ALTER TABLE will change the file
# not sure how to run multiple changes at once, so just run them multiple times
csvq "ALTER TABLE \`${INPUT_FILE_PATH}\` DROP domain"
csvq "ALTER TABLE \`${INPUT_FILE_PATH}\` DROP pathname"

original_headers=$(head -n1 "${INPUT_FILE_PATH}")

touch "${OUTPUT_FILE_PATH}"
# remove csv header
sed -i '1d' "${INPUT_FILE_PATH}"

echo "[+] Proccessing final output"
final_output_body=$(paste "${TMP_DOMAIN_COLUMN}" "${TMP_PATHNAME_COLUMN}" "${INPUT_FILE_PATH}" -d ',')
final_output_headers="domain,pathname,${original_headers}"

# it will look like
# domain,pathname,url,redirectlocation,position,status_code,content_length,content_words,content_lines,content_type,resultfile
# https://subdomain.example.com,def,https://subdomain.example.com:443/def,https://anothersubdomain.example.com/auth/?request=20fb4090-69e5-42c1-b23d-ca5c70004ba8&rd=https://subdomain.example.com:443%2Fdef,9,302,138,3,8,text/html,
# ...
# always echo with newline here (default option). this is really critical when appending a file to another                                                                       
echo "${final_output_body}" | sed -e "1 i\\${final_output_headers}" > "${OUTPUT_FILE_PATH}"
echo "[+] Done"

# ffuf monkeypatch end
#################
