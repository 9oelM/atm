#!/bin/bash
####################################################
# @9oelm
####################################################

cat <<EOF
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

atm-find-urls.sh         

extracts URLs of all available resources (js, css, png, ...) that have URLs from domains
EOF


declare -a all_commands=("openssl" "cat" "sort" "echo" "awk" "pwd" "grep" "gau" "hakrawler" "getJS" "unfurl" "timeout")
all_commands_length=${#array[@]}

for i in ${!all_commands[@]}; do
    if ! command -v "${all_commands[i]}" >"/dev/null"; then
        echo "[!] Command ${all_commands[i]} does not exist. You need to install it first. View README.md for installation instructions."
        exit
    fi
done

echo "[+] All prerequisite tools exist. Proceeding..."

THREADS="8"
ONLY_ONE_FILE=""
TIMEOUT_SECONDS="180"
SEARCH_DEPTH="2"
usage="
usage:
-o [required] output directory
-t [optional] number of threads.
              IMPORTANT: high number of threads will get rate limited and won't give a satisfiable result. 
              (default ${THREADS})
-e [optional] domain regex patterns to exclude from scanning, separated by a single space (you need to use double quotes around it)
              you can also use this to prevent scanning unwanted redirects.
              you don't need to insert ^ and $ at the beginning and the end of each pattern. They're inserted automatically.
              example: \"notthissubdomain\.example\.com ([0-9]*)\.example\.com\"
-a [optional] only store results in one file (all.txt) instead of creating domain.txt for each domain.
              **must be specified as -a true** if used
-l [optional] length of timeout in seconds, for scanning each domain supplied. (default 180 seconds)
              you may need this because gau may fall in a never-ending scanning if it scans a large website.
-s [optional] search depth for hakrawler. you may want to increase this to 3 or 4 if you want deeper inspection. (default 2)
-h help

example: cat domains.txt | atm-find-urls.sh -o output
"
while getopts t:o:a:l:s:e:h: flag; do
    case "${flag}" in
    t)
        THREADS=${OPTARG}
        ;;
    o)
        OUTPUT_DIR=${OPTARG}
        ;;
    a)
        ONLY_ONE_FILE=${OPTARG}
        ;;
    l)
        TIMEOUT_SECONDS=${OPTARG}
        ;;
    s)
        SEARCH_DEPTH=${OPTARG}
        ;;
    e)
        EXCLUDED_DOMAINS=${OPTARG}
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

EXCLUDED_DOMAINS_ARRAY=$(echo "${EXCLUDED_DOMAINS}" | sed 's/ /\n/g')
export EXCLUDED_DOMAINS_ARRAY

stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input into this script."
    echo "${usage}"
    echo "[!] No stdin detected. Pipe input into this script."
    exit
fi

[ -z "$OUTPUT_DIR" ] && echo "[!] -o flag was not specified. Please try again." && exit

echo "[+] CLI options:"
echo -e "[+] threads=${THREADS}\n[+] output_dir=${OUTPUT_DIR}\n[+] only_one_file=${ONLY_ONE_FILE}"

RAND_STR=$(openssl rand -hex 12)
TMP_DIR=".tmp-${RAND_STR}"
echo "[+] Creating temp dir at ./${TMP_DIR}"
mkdir "./${TMP_DIR}"
mkdir -p "${OUTPUT_DIR}" >/dev/null 2>$1

function cleanup {
  echo "[+] Removing "${TMP_DIR}" before exit"
  rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

DOMAINS_WITH_HTTPS_FILE_PATH="./${TMP_DIR}/domains_with_https.lst"
# store the history of all redirected URLs here
REDIRECTED_URLS_FILE_PATH="./${TMP_DIR}/redirected_urls.lst"
export REDIRECTED_URLS_FILE_PATH
touch "${REDIRECTED_URLS_FILE_PATH}"
# @todo support http
# this line is needed because the way tools format domain is not standardized.
# some accept domains without http or with http or output domains without or with https.
# to remove confusion, just prefix https to all domains for now
echo "${stdin}" | unfurl --unique format https://%d | awk NF > "${DOMAINS_WITH_HTTPS_FILE_PATH}"

# returns IS_REDIRECTED_TO_OUTSIDE as 'true' if redirected from abc.google.com to asdf.somewhereelse.com
# returns IS_REDIRECTED_TO_OUTSIDE as 'false' if redirected from abc.google.com to def.google.com
function check_redirect(){
    domain="$1"
    # https://stackoverflow.com/questions/17336915/return-value-in-a-bash-function
    local -n IS_REDIRECTED_TO_OUTSIDE="$2"
    local -n REDIRECTED_URL="$3"
    IS_REDIRECTED_TO_OUTSIDE="false" # defaults to false 
    maybe_redirected_url=`curl -Ls -o /dev/null -w %{url_effective} ${domain}`
    redirected_url_root_domain=`echo "${maybe_redirected_url}" | unfurl format %r.%t`
    root_domain=`echo "${domain}" | unfurl format %r.%t` # abc.google.com/abc?abc=abc -> google.com

    [ "${redirected_url_root_domain}" != "${root_domain}" ] && IS_REDIRECTED_TO_OUTSIDE="true"
    REDIRECTED_URL="${maybe_redirected_url}"  
}
export -f check_redirect

function scan_links_from_domain() {
    # just don't want to think about closure, so receive them as args
    domain="$1"
    tmp_dir="$2"
    output_dir="$3"
    DOMAIN_NAME=$(echo "${domain}" | unfurl format %d) # https://google.com --> google.com
    echo "[+] Processing ${DOMAIN_NAME}..."
    FILE_PREFIX="$4"
    ONLY_ONE_FILE="$5"
    TIMEOUT_SECONDS="$6"
    SEARCH_DEPTH="$7"
    # if $4 is not defined, default to the domain name
    if [ -z "${FILE_PREFIX}" ]; then
        FILE_PREFIX="${DOMAIN_NAME}"
    fi

    echo "[+] Initiating scan on ${domain}"

    # If there is a redirect..
    check_redirect $domain is_redirected_to_outside redirected_url
    clean_redirected_domain="$(echo ${redirected_url} | unfurl format %d)"
    already_visited_this_redirected_domain=$(cat "${REDIRECTED_URLS_FILE_PATH}" | grep -E "^${clean_redirected_domain}$")

    # 0. If the domain or redirected domain is excluded explicitly by user, ignore it
    for excluded_domain_pattern in ${EXCLUDED_DOMAINS_ARRAY[@]}; do
        is_domain_excluded=$(echo "${DOMAIN_NAME}" | grep -E "^${excluded_domain_pattern}$")
        if [[ ! -z "${is_domain_excluded}" ]]; then
            echo "[+] ${DOMAIN_NAME} is ignored by the pattern supplied from -e flag: ${excluded_domain_pattern}"
            return 0
        fi 
        is_redirected_url_excluded=$(echo "$redirected_url" | grep -E "^${excluded_domain_pattern}$")
        if [[ ! -z "${is_redirected_url_excluded}" ]]; then
            echo "[+] ${DOMAIN_NAME} is redriected to ${redirected_url}, but this redirect is ignored by the pattern supplied from -e flag"
            return 0
        fi 
    done

    # 1. If a redirect is to a different root domain, ignore it
    if [[ "${is_redirected_to_outside}" == "true" ]]; then
        echo "[+] Ignorinig ${domain} because it redirects to ${redirected_url} which is outside of its original root domain." 
        return 0
    # 2. If a redirect has been visited, ignore it
    elif [[ ! -z "${already_visited_this_redirected_domain}" ]]; then
        echo "[+] Ignorinig ${domain} because this redirect has been visited once"
        return 0
    # 3. If there is a redirect inside the root domain, record the redirect and proceed
    elif [[ "${clean_redirected_domain}" != "${DOMAIN_NAME}" ]]; then
        echo "[+] ${domain} redirects to ${clean_redirected_domain}. Will scan ${clean_redirected_domain} instead"
        echo "${clean_redirected_domain}" >> "${REDIRECTED_URLS_FILE_PATH}"
        domain="${clean_redirected_domain}"
    fi


    commands_to_run="echo \"${domain}\" | timeout ${TIMEOUT_SECONDS} gau --blacklist png,jpg,gif --threads 12 --o \"${tmp_dir}/${FILE_PREFIX}.gau.output.lst\""
    commands_to_run="${commands_to_run}\necho \"${domain}\" | timeout ${TIMEOUT_SECONDS} hakrawler -d ${SEARCH_DEPTH} -t 12 -insecure | sort -u > \"${tmp_dir}/${FILE_PREFIX}.hakralwer.output.lst\""
    # seems like getJS does not have a slient option?
    commands_to_run="${commands_to_run}\necho \"${domain}\" | timeout ${TIMEOUT_SECONDS} getJS --complete --resolve --insecure --output \"${tmp_dir}/${FILE_PREFIX}.getJS.output.lst\" > /dev/null"
    echo -e $commands_to_run | xargs -P 3 -I % bash -c '`%`;'
    
    # hakrawler sometimes just outputs a file path like /this-file.js without full URL, so fix that
    touch "${tmp_dir}/${FILE_PREFIX}.hakralwer.output.tmp.lst" 
    while read line; do 
        if [[ ! "$line" =~ ^(http)s?:\/\/ ]]; then
            # @todo support http 
            # prefixing DOMAIN_NAME is the best guess, but it might be wrong.
            echo "https://${DOMAIN_NAME}${line}" >> "${tmp_dir}/${FILE_PREFIX}.hakralwer.output.tmp.lst" 
        else
            echo "${line}" >> "${tmp_dir}/${FILE_PREFIX}.hakralwer.output.tmp.lst" 
        fi
    done < "${tmp_dir}/${FILE_PREFIX}.hakralwer.output.lst"
    rm "${tmp_dir}/${FILE_PREFIX}.hakralwer.output.lst"
    mv "${tmp_dir}/${FILE_PREFIX}.hakralwer.output.tmp.lst" "${tmp_dir}/${FILE_PREFIX}.hakralwer.output.lst"
    
    # getJS sometimes just outputs a file path with a double slash for some reason, like google.com//this-file.js, so fix that 
    touch "${tmp_dir}/${FILE_PREFIX}.getJS.output.tmp.lst" 
    while read line; do 
        correct_url=$(echo "${line}" | sed -e 's/\/\//\//g' | sed -e 's/^https:\//https:\/\//g' | sed -e 's/^http:\//http:\/\//g')
        if [[ ! "$correct_url" =~ ^https:\/\/ ]]; then
            # @todo support http
            correct_url="https://${line}" 
        fi

        echo "$correct_url" >> "${tmp_dir}/${FILE_PREFIX}.getJS.output.tmp.lst"  
    done < "${tmp_dir}/${FILE_PREFIX}.getJS.output.lst"
    rm "${tmp_dir}/${FILE_PREFIX}.getJS.output.lst"
    mv "${tmp_dir}/${FILE_PREFIX}.getJS.output.tmp.lst" "${tmp_dir}/${FILE_PREFIX}.getJS.output.lst"

    echo "[+] Completed gathering links from ${FILE_PREFIX}"

    DOMAIN_ALL_OUTPUT_FILE_PATH="${tmp_dir}/${FILE_PREFIX}.all.output.lst"
    cat "${tmp_dir}/${FILE_PREFIX}.gau.output.lst" "${tmp_dir}/${FILE_PREFIX}.hakralwer.output.lst" "${tmp_dir}/${FILE_PREFIX}.getJS.output.lst" | sort -u | awk NF > "${DOMAIN_ALL_OUTPUT_FILE_PATH}"
    # if -a option is given, do not produce result file for each domain supplied. instead, forward all output to all.txt
    [ ! "${ONLY_ONE_FILE}" ] && cp "${DOMAIN_ALL_OUTPUT_FILE_PATH}" "${output_dir}/${FILE_PREFIX}.txt"
    # cat with no trailing newline
    cat "${DOMAIN_ALL_OUTPUT_FILE_PATH}" | awk NF >> "${output_dir}/all.txt"

    rm "${tmp_dir}/${FILE_PREFIX}.gau.output.lst" "${tmp_dir}/${FILE_PREFIX}.hakralwer.output.lst" "${tmp_dir}/${FILE_PREFIX}.getJS.output.lst" "${DOMAIN_ALL_OUTPUT_FILE_PATH}"
}
export -f scan_links_from_domain

cat "${DOMAINS_WITH_HTTPS_FILE_PATH}" | xargs -d "\n" -I CMD -n 1 -P "${THREADS}" bash -c "scan_links_from_domain CMD \"${TMP_DIR}\" \"${OUTPUT_DIR}\" \"\" \"${ONLY_ONE_FILE}\" \"${TIMEOUT_SECONDS}\" \"${SEARCH_DEPTH}\";"
sort -u "${OUTPUT_DIR}/all.txt" | awk NF > "${OUTPUT_DIR}/all.uniq.txt" 
rm "${OUTPUT_DIR}/all.txt" 
mv "${OUTPUT_DIR}/all.uniq.txt" "${OUTPUT_DIR}/all.txt" 
echo "[+] Job finished"
