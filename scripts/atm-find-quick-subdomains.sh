#!/bin/bash

THREADS="5"
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

atm-find-quick-subdomains.sh

quickly gathers subdomains of multiple root domains with multithreading

example:
atm-find-quick-subdomains.sh -t 15 -d hackerone,google.com,shopify.com

usage:
-o [required] [string] path to output directory
-d [required] [string] root domains to search subdomains for, delimited by comma
                       example: -d \"a.example.com,b.example.com\"
-t [optional] [int] number of threads (default: ${THREADS})
"

declare -a all_commands=("openssl" "sublist3r" "assetfinder" "subfinder" "crobat")
all_commands_length=${#array[@]}

for i in ${!all_commands[@]}; do
    if ! command -v "${all_commands[i]}" >"/dev/null"; then
        echo "[!] Command ${all_commands[i]} does not exist. You need to install it first. Run:
        go install github.com/cgboal/sonarsearch/cmd/crobat@latest
        
        "
        exit 1
    fi
done

while getopts t:o:d:h: flag; do
    case "${flag}" in
    t)
        THREADS=${OPTARG}
        ;;
    o)
        OUTPUT_DIR=${OPTARG}
        ;;
    d)
        ROOT_DOMAINS=${OPTARG}
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

[ -z "${ROOT_DOMAINS}" ] && echo "[!] -d option is not specified. Please try again." && printf "${usage}" && echo "[!] -d option is not specified. Please try again." && exit 1
[ -z "${OUTPUT_DIR}" ] && echo "[!] -o option is not specified. Please try again." && printf "${usage}" && echo "[!] -o option is not specified. Please try again." && exit 1
# directory may exist already
[ -d "${OUTPUT_DIR}" ] || mkdir -p "${OUTPUT_DIR}"

export OUTPUT_DIR

RAND_STR=$(openssl rand -hex 12)
TMP_DIR=".tmp-${RAND_STR}"
mkdir "./${TMP_DIR}"
export TMP_DIR

function cleanup {
  echo "[+] Removing "${TMP_DIR}" before exit"
  rm -rf "./${TMP_DIR}"
}

function find_domains(){
    root_domain="$1"

    RAND_STR_0="sublist3r-$(openssl rand -hex 12)"
    RAND_STR_1="assetfinder-$(openssl rand -hex 12)"
    RAND_STR_2="subfinder-$(openssl rand -hex 12)"
    RAND_STR_3="crobat-$(openssl rand -hex 12)"

    echo "[+] Scanning ${root_domain}"

    domain_recon_commands="sublist3r -d ${root_domain} -o \"./${TMP_DIR}/${RAND_STR_0}\" >/dev/null"
    domain_recon_commands="${domain_recon_commands}\nassetfinder -subs-only ${root_domain} > \"./${TMP_DIR}/${RAND_STR_1}\""
    domain_recon_commands="${domain_recon_commands}\nsubfinder -d ${root_domain} -silent -o \"./${TMP_DIR}/${RAND_STR_2}\" >/dev/null"
    domain_recon_commands="${domain_recon_commands}\ncrobat -s ${root_domain} > \"./${TMP_DIR}/${RAND_STR_3}\""
    echo -e "$domain_recon_commands" | xargs -P 4 -I % bash -c '`%`;'

    # I know all domains should be in the correct format already but just wanna prevent any unknown bugs
    sanitized_root_domain=$(echo "${root_domain}" | sed -e 's/[^A-Za-z0-9._-]/_/g')
    cat "./${TMP_DIR}/${RAND_STR_0}" "./${TMP_DIR}/${RAND_STR_1}" "./${TMP_DIR}/${RAND_STR_2}" "./${TMP_DIR}/${RAND_STR_3}" | sort -u > "${OUTPUT_DIR}/${sanitized_root_domain}.lst"
}
export -f find_domains

ROOT_DOMAINS_DELIMITED_BY_NEWLINES=$(echo -n ${ROOT_DOMAINS} | sed -e 's/\s//g; s/\,/\n/g' | uniq)

echo "[+] Recevied:"
echo "${ROOT_DOMAINS_DELIMITED_BY_NEWLINES}"

echo -n "${ROOT_DOMAINS_DELIMITED_BY_NEWLINES}" | xargs -P "${THREADS}" -I % bash -c 'find_domains %;'

rm -rf "./${TMP_DIR}"
echo "[+] Done"