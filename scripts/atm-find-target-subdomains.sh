#!/bin/bash

# https://circleci.com/docs/2.0/using-shell-scripts/
# Exit script if a statement returns a non-true return value.
set -o errexit
# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o 
# Display commands and their arguments as they are executed
set -x

AMASS_TIMEOUT=15
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

atm-find-target-subdomains.sh

gathers subdomains from a target YAML file.
to be mainly used inside github actions.

example:
atm-find-target-subdomains.sh -d ./targets -t shopify -o ./output

usage:
-d [required] [string] target file's directory
-t [required] [string] target file name
-o [required] [string] output directory
-i [optional] [string] timeout in minutes for amass. default: ${AMASS_TIMEOUT}
"

while getopts t:d:o:m:h: flag; do
    case "${flag}" in
    t)
        TARGET=${OPTARG}
        ;;
    d)
        TARGET_DIR=${OPTARG}
        ;;
    o)
        OUTPUT_DIR=${OPTARG}
        ;;
    m)
        AMASS_TIMEOUT=${OPTARG}
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

[ -z "${TARGET}" ] || [ -z "${TARGET_DIR}" ] || [ -z "${OUTPUT_DIR}" ] && echo "All flags are necessary. Please check again." && printf "${usage}" && echo "All flags are necessary. Please check again."  && exit 1  

[ ! -d "${TARGET_DIR}" ] && echo "${TARGET_DIR} does not exist. Check again." && exit 1

[ -d "${OUTPUT_DIR}" ] || mkdir -p "${OUTPUT_DIR}"

[ ! -f "${TARGET_DIR}/${TARGET}.yml" ] && echo "${TARGET_DIR}/${TARGET}.yml does not exist." && exit 1

export TARGET
export TARGET_DIR
export OUTPUT_DIR
export AMASS_TIMEOUT

# before running this script, all other scripts should be installed in the system,
# and should be accessible (added to $PATH)
root_domains=$(atm-parse-target-yml.sh "${TARGET_DIR}/${TARGET}.yml" ".domains.in_scope.wildcard[]" ",")
root_domains_delimited_by_newline=$(atm-parse-target-yml.sh "${TARGET_DIR}/${TARGET}.yml" ".domains.in_scope.wildcard[]")
excluded_subdomains_delimited_by_pipe="$(atm-parse-target-yml.sh "${TARGET_DIR}/${TARGET}.yml" ".domains.out_scope.wildcard[]" "|" || true)"
if [ -z "${excluded_subdomains_delimited_by_pipe}" ]; then
    excluded_subdomains_delimited_by_pipe=$(atm-parse-target-yml.sh "${TARGET_DIR}/${TARGET}.yml" ".domains.out_scope.single[]" "|" || true)
else
    excluded_subdomains_delimited_by_pipe="${excluded_subdomains_delimited_by_pipe}|$(atm-parse-target-yml.sh "${TARGET_DIR}/${TARGET}.yml" ".domains.out_scope.single[]" "|" || true)"
fi 

export root_domains
export root_domains_delimited_by_newline

export CHAOS_OUTPUT="${OUTPUT_DIR}/chaos"
export AMASS_OUTPUT="${OUTPUT_DIR}/amass"
export QUICK_OUTPUT="${OUTPUT_DIR}/quick"

echo "[+] Starting"

####################
# download subdomains from chaos
####################
function get_subdomains_from_chaos() {
    echo "[+] Staring getting subdomains from chaos"
    chaos_zip_link=$(atm-parse-target-yml.sh "${TARGET_DIR}/${TARGET}.yml" ".domains.chaos_zip_link")
    chaos_subdomains_downloaded="${OUTPUT_DIR}/chaos-${TARGET}.zip"

    # this contains files as {subdomain}.txt.
    # example:
    # shopify.com.txt
    # shopifycloud.com.txt
    # this is null if no link was provided
    if [ "${chaos_zip_link}" != "null" ]; then
        if ! command -v "unzip" >"/dev/null"; then
            apt-get -y install unzip
        fi
        curl "${chaos_zip_link}" -o "${chaos_subdomains_downloaded}"
        unzip -o "${chaos_subdomains_downloaded}" -d "${CHAOS_OUTPUT}"
        rm -rf "${chaos_subdomains_downloaded}"
    fi
    echo "[+] Finished getting subdomains from chaos"
}
export -f get_subdomains_from_chaos

####################
# run amass
####################
function get_subdomains_from_amass() {
    # amass will produce following files: amass.json, amass.log, amass.txt, indexes.bolt
    # amass.txt will contain the list of all subdomains (mixed if multiple root domains)
    # max 15 mins
    echo "[+] Starting getting subdomains from amass"
    echo "[+] AMASS_TIMEOUT: ${AMASS_TIMEOUT}"
    # max 15 mins
    amass enum -timeout "${AMASS_TIMEOUT}" -d "${root_domains}" -dir "${AMASS_OUTPUT}"
    echo "[+] Finished getting subdomains from amass"
}
export -f get_subdomains_from_amass

####################
# run custom script to collect subdomains
####################
function get_subdomains_from_custom_script() {
    echo "[+] Staring getting subdomains from custom script"
    atm-find-quick-subdomains.sh -t "10" -d "${root_domains}" -o "${QUICK_OUTPUT}"
    echo "[+] Finished getting subdomains from custom script"
}
export -f get_subdomains_from_custom_script

# OUTPUT_DIR
# |- amass
# |- quick
# |- chaos

# run all of them together
parallel --ungroup -j3 ::: get_subdomains_from_amass get_subdomains_from_chaos get_subdomains_from_custom_script

# somehow `set` command needs to be turned off here to make success
# DO NOT exit script if a statement returns a non-true return value.
set +o errexit
# DO NOT use the error status of the first failure, rather than that of the last item in a pipeline.
set +o
# process gathered subdomains
echo "${root_domains_delimited_by_newline}" | xargs -P "3" -I % bash -c "touch ${OUTPUT_DIR}/%.tmp.txt"
echo "${root_domains_delimited_by_newline}" | xargs -P "3" -I % bash -c "cat \"${AMASS_OUTPUT}/amass.txt\" | grep \"%\" >> \"${OUTPUT_DIR}/%.tmp.txt\""
# chaos may not have all of the in-scope domains
echo "${root_domains_delimited_by_newline}" | xargs -P "3" -I % bash -c "cat \"${CHAOS_OUTPUT}/%.txt\" >> \"${OUTPUT_DIR}/%.tmp.txt\" || true"
echo "${root_domains_delimited_by_newline}" | xargs -P "3" -I % bash -c "cat \"${QUICK_OUTPUT}/%.lst\" >> \"${OUTPUT_DIR}/%.tmp.txt\""

if [ ! -z "${excluded_subdomains_delimited_by_pipe}" ]; then
    echo "${root_domains_delimited_by_newline}" | xargs -P "3" -I % bash -c "cat \"${OUTPUT_DIR}/%.tmp.txt\" | sort -u | grep -Ev \"${excluded_subdomains_delimited_by_pipe}\" > \"${OUTPUT_DIR}/%.txt\""
else
    echo "${root_domains_delimited_by_newline}" | xargs -P "3" -I % bash -c "cat \"${OUTPUT_DIR}/%.tmp.txt\" | sort -u > \"${OUTPUT_DIR}/%.txt\""
fi

wc "${OUTPUT_DIR}"/*.txt
rm -rf "${OUTPUT_DIR}"/*.tmp.txt

mkdir "${OUTPUT_DIR}/all-domains"
mv "${OUTPUT_DIR}"/*.txt "${OUTPUT_DIR}/all-domains"
echo "[+] Done"
