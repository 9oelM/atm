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

atm-download-files-from-urls.sh

downloads files from URLs supplied from stdin.

checks duplicate files with \`comp\` command and ignores if already downloaded.
files are considered to be duplicate if:
- they have the same file name
- the the output from comp command tells they are the same

files are saved with a format of:
OUTPUT_DIR/{domain}-{file_name_without_extension}.{some_unique_hash}-atm.{file_extension}
example: google.com-_buildManifest.aa7d9093cf-atm.js

usage:
-o [required] output directory
-t [optional] number of threads (default 15)
-l [optional] length of timeout in seconds for each request (default 10)
-h help

example:
cat my-file-urls.txt | ./atm-download-files-from-urls.sh -o files -t 10
"

NUM_THREADS="15"
TIMEOUT_SECONDS="10"
while getopts o:t:l:h: flag; do
    case "${flag}" in
    o)
        OUTPUT_DIR=${OPTARG}
        ;;
    t)
        NUM_THREADS=${OPTARG}
        ;;
    l)
        TIMEOUT_SECONDS=${OPTARG}
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

[ -z "${OUTPUT_DIR}" ] && echo "[!] -o option is not specified. Please try again." && exit
# directory may exist already
[ -d "${OUTPUT_DIR}" ] || mkdir -p "${OUTPUT_DIR}"

stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input into this script."
    echo "    Example: cat myurls.txt | ./atm-download-files-from-urls.sh -o|-t|-l"
    exit
fi

function download_and_ignore_file_if_same() {
    OUTPUT_DIR="$1"
    # https://google.com/asset/main.js
    ORIGINAL_FILE_URL="$2"

    # DOMAIN=$(echo "${ORIGINAL_FILE_URL}" | unfurl format %d)
    # /asset/main.js
    ORIGINAL_FILE_URL_PATH=$(echo "${ORIGINAL_FILE_URL}" | unfurl format %p)
    SANITIZED_DOMAIN_FILENAME=$(echo "${ORIGINAL_FILE_URL}" | unfurl format %d | sed -e 's/[^A-Za-z0-9._-]/_/g')
    # main.js
    ORIGINAL_FILE_URL_LAST_PATH=$(basename "${ORIGINAL_FILE_URL_PATH}")
    ORIGINAL_FILE_EXTENSION="${ORIGINAL_FILE_URL_LAST_PATH##*.}"
    ORIGINAL_FILE_NAME_WITHOUT_EXTENSION="${ORIGINAL_FILE_URL_LAST_PATH%.*}"

    # used to identify each file with a URL by prefixing it

    # todo multithreading issue 
    # if the file of the same name already exists, compare the contents
    TMP_FILE_NAME="$(openssl rand -hex 5).atm-tmp"
    # without timeout, it will get stuck
    wget --timeout=10 --tries=1 --no-check-certificate -q --show-progress -O "${OUTPUT_DIR}/${TMP_FILE_NAME}" "${ORIGINAL_FILE_URL}"
    (
        # mutex lock is needed because multithreading from xargs is taking place,
        # and we are dealing with file existence 
        flock -x -w 1 200 || exit 1
        uniq_file_hash=".$(openssl rand -hex 5)-atm."

        maybe_duplicate_files="$OUTPUT_DIR"/*-"$ORIGINAL_FILE_NAME_WITHOUT_EXTENSION".*-atm."$ORIGINAL_FILE_EXTENSION"

        # if duplicate files exist
        if compgen -G "${maybe_duplicate_files}" > /dev/null; then
            # ls not working with a variable for some reason 
            all_duplicate_named_file_paths=$(ls "$OUTPUT_DIR"/*-"$ORIGINAL_FILE_NAME_WITHOUT_EXTENSION".*-atm."$ORIGINAL_FILE_EXTENSION" 2> /dev/null)
            for duplicate_named_file_path in $all_duplicate_named_file_paths; do
                if cmp --silent -- "${duplicate_named_file_path}" "${OUTPUT_DIR}/${TMP_FILE_NAME}"; then
                    # file contents are identical, delete the tmp file
                    echo "${ORIGINAL_FILE_URL} is a duplicate with ${duplicate_named_file_path}. Ignoring it."
                    rm "${OUTPUT_DIR}/${TMP_FILE_NAME}"

                    # no need to proceed anymore. just finish the function 
                    exit 1
                fi
            done;
        fi
        # otherwise, name the file as something different
        # this file really contains something different. the name is the only thing that's the same
        output_path="${OUTPUT_DIR}/${SANITIZED_DOMAIN_FILENAME}-${ORIGINAL_FILE_NAME_WITHOUT_EXTENSION}${uniq_file_hash}${ORIGINAL_FILE_EXTENSION}"
        echo "Saving ${output_path}"
        # mv [something] output/google.com-main-bundle.a139vbae-atm.js
        mv "${OUTPUT_DIR}/${TMP_FILE_NAME}" "${output_path}"
    ) 200> /var/lock/.atm-get-files-from-urls.exclusivelock
}
export -f download_and_ignore_file_if_same

echo "${stdin}" | xargs -P "${NUM_THREADS}" -I % bash -c "download_and_ignore_file_if_same \"${OUTPUT_DIR}\" \"%\";"

how_many_files_were_downloaded=$(ls "${OUTPUT_DIR}" | wc -l)
echo "${how_many_files_were_downloaded} files were downloaded"
echo "Job done"