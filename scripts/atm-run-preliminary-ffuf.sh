#!/bin/bash
# Display commands and their arguments as they are executed
set -x
trap "exit" INT

SILENT=0
THREADS="100"
WORDLIST_PATH="/usr/share/wordlists/seclists/Discovery/Web-Content/big.txt"
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

atm-run-preliminary-ffuf.sh

runs a preliminary ffuf scan on domains. because it's preliminary, it does not do any recursive scan.
the output of this script can be again piped into atm-run-detailed-ffuf.sh for recursive checks.
the main reason this is only preliminary is that it gives a chance for a hacker to intercept and have a look at the preliminary findings
before a detailed check is going to be done.

it is best recommended that you input an output from atm-find-working-urls.sh into this script
because that is going to save some time. otherwise, make sure you only input domains that are actually up.

IMPORTANT: ffuf 1.3.1 (latest version as of now) has a bug in producing csv: https://github.com/ffuf/ffuf/issues/502
           this script runs atm-monkeypatch-ffuf-csv-output.sh automatically to fix that.

example:
atm-run-preliminary-ffuf.sh -w mycustomwordlist.txt -o output.csv -d domains-prefixed-with-http.txt -t 120 

usage:
-o [required] [string] output file path. the output is always in csv.
-d [required] [string] the list of domains to be scanned. 
                       a domain needs to be with https?:// prefix and without trailing slash at the end.
                       example:
                       http://a.example.com
                       https://b.example.com
-w [optional] [string] path to wordlist (will be an input to FUZZ). (default: ${WORDLIST_PATH}) 
                       you need to supply your own wordlist if you don't have ${WORDLIST_PATH}.
-t [optional] [int] number of threads. (default: ${THREADS})
-s [optional] [0|1] reduces verbosity. may be useful when excessive output needs to be prevented in some cases like CI environments. (default: ${SILENT})
-h help
"

while getopts p:w:o:d:t:s:h: flag; do
    case "${flag}" in
    w)
        WORDLIST_PATH=${OPTARG}
        ;;
    o)
        OUTPUT_FILE_PATH=${OPTARG}
        ;;
    d)
        DOMAIN_LIST_PATH=${OPTARG}
        ;;
    t)
        THREADS=${OPTARG}
        ;;
    s)
        SILENT=${OPTARG}
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


declare -a all_commands=("ffuf" "unfurl" "csvq")
all_commands_length=${#array[@]}

for i in ${!all_commands[@]}; do
    if ! command -v "${all_commands[i]}" >"/dev/null"; then
        echo "[!] Command ${all_commands[i]} does not exist. You need to install it first. View README.md for installation instructions."
        exit
    fi
done

if [ -z "${OUTPUT_FILE_PATH}" ] || [ -z "${DOMAIN_LIST_PATH}" ]; then
    echo "[!] all options except -w and -t are necessary. Please check again if you have missed any input."
    echo "${usage}"
    echo "[!] all options except -w and -t are necessary. Please check again if you have missed any input."
    exit
fi

if [ -f "${OUTPUT_FILE_PATH}" ]; then
    echo "[!] -o option: \"${OUTPUT_FILE_PATH}\" file already exists. Please check again."
    echo "${usage}"
    echo "[!] -o option: \"${OUTPUT_FILE_PATH}\" file already exists. Please check again."
    exit
fi

if [ ! -f "${WORDLIST_PATH}" ]; then
    echo "[!] -w option: \"${WORDLIST_PATH}\" does not exist. Please check again."
    echo "${usage}"
    echo "[!] -w option: \"${WORDLIST_PATH}\" does not exist. Please check again."
    exit
fi

if [ ! -f "${DOMAIN_LIST_PATH}" ]; then
    echo "[!] -d option: \"${DOMAIN_LIST_PATH}\" does not exist. Please check again."
    echo "${usage}"
    echo "[!] -d option: \"${DOMAIN_LIST_PATH}\" does not exist. Please check again."
    exit
fi

# ffuf has a memory problem when too many logs get accumulated (the system will kill it). Therefore divide the wordlist into multiple parts and merge the output later
# split -l 10000 file.txt
# split -l "${WORDLIST_PATH}"
# split -l 500000 
# 500000 is the number of lines we target per csv file
# then it should be (number of domains) * (number of words per ffuf run) = 500000
# and so (number of words per ffuf run) = 500000 / (number of domains)

number_of_domains=$(wc -l "${DOMAIN_LIST_PATH}" | cut -f 1 -d ' ')

if [[ "${number_of_domains}" == "0" ]]; then
    echo "[!] No alive domains were detected. Exiting."
    exit 0
fi

lines_per_csv_file=500000
# automatically rounds up
# if number_of_domains is 10,000, number_of_words_per_one_ffuf_run will be 5, which is fine
number_of_words_per_one_ffuf_run=$(( $lines_per_csv_file / $number_of_domains ))

# happens when $lines_per_csv_file > $number_of_domains. unlikely but possible
if [[ "${number_of_words_per_one_ffuf_run}" == "0" ]]; then
    number_of_words_per_one_ffuf_run="2000"
fi

TMP_WORDLIST_DIRECTORY=".tmp-atm-$(openssl rand -hex 5)"

trap '
  trap - INT # restore default INT handler
  kill -s INT "$$"
' INT

function cleanup {
  echo "[+] Removing "${TMP_WORDLIST_DIRECTORY}" before exit"
  rm -rf "${TMP_WORDLIST_DIRECTORY}"
}

trap cleanup EXIT
mkdir "./${TMP_WORDLIST_DIRECTORY}" 

split -l "${number_of_words_per_one_ffuf_run}" --additional-suffix=".atm-wordlist" "${WORDLIST_PATH}"

mv ./*".atm-wordlist" "./${TMP_WORDLIST_DIRECTORY}"

index=1
total_small_wordlists_count=$(ls -1 "./${TMP_WORDLIST_DIRECTORY}" | wc -l | cut -f 1 -d ' ')
echo "[+] Generated split wordlists:"
wc -l "./${TMP_WORDLIST_DIRECTORY}"/*

if command -v "workflow-send-telegram-message.sh" >"/dev/null"; then
    workflow-send-telegram-message.sh "run ffuf" "Total ${total_small_wordlists_count} wordlists need to be enumerated" || true
fi

for small_wordlist in "${TMP_WORDLIST_DIRECTORY}"/*.atm-wordlist; do
    tmp_csv_output="tmp-atm-$(openssl rand -hex 5).csv"
    monkeypatched_csv_output="tmp-atm-$(openssl rand -hex 5).csv"
    
    if [ "${SILENT}" == "0" ]; then
        ffuf -mode=clusterbomb -ic -t "${THREADS}" -w "${DOMAIN_LIST_PATH}":DOMAIN -w "./${small_wordlist}":PATHNAME -u DOMAIN/PATHNAME -o "${tmp_csv_output}" -of csv -fr 'not found|404'
    else
        ffuf -mode=clusterbomb -ic -t "${THREADS}" -w "${DOMAIN_LIST_PATH}":DOMAIN -w "./${small_wordlist}":PATHNAME -u DOMAIN/PATHNAME -o "${tmp_csv_output}" -of csv -fr 'not found|404' -s 1
    fi
    atm-monkeypatch-ffuf-csv-output.sh -i "${tmp_csv_output}" -o "${monkeypatched_csv_output}"
    rm "${tmp_csv_output}"
    output_csv_header=$(head -n1 "${monkeypatched_csv_output}")
    
    if [ ! -f "${OUTPUT_FILE_PATH}" ]; then
        touch "${OUTPUT_FILE_PATH}"
        cat "${monkeypatched_csv_output}" >> "${OUTPUT_FILE_PATH}"
    else
        # without the first line, which is the csv header
        cat "${monkeypatched_csv_output}" | sed -n '1d;p' >> "${OUTPUT_FILE_PATH}"
    fi

    rm "${monkeypatched_csv_output}"

    if command -v "workflow-send-telegram-message.sh" >"/dev/null"; then
        workflow-send-telegram-message.sh "run ffuf" "${index} of ${total_small_wordlists_count} wordlists done" || true
    fi

    echo "
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
${index} of ${total_small_wordlists_count} wordlists done
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    "
    index=$(( index + 1 ))
done

rm -rf "${TMP_WORDLIST_DIRECTORY}"

wc "${OUTPUT_FILE_PATH}"
echo "[+] Done"
