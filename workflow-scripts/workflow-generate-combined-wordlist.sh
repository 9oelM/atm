#!/bin/bash
###
# generates combined wordlist file called combined_wordlist.txt at PWD 
###
set -x

while getopts t:w:r: flag; do
    case "${flag}" in
    t)
        ffuf_wordlist_type=${OPTARG}
        ;;
    w)
        ffuf_custom_wordlist_file_name=${OPTARG}
        ;;
    r)
        ffuf_wordlist_min_max_range=${OPTARG}
        ;;
    *) 
        printf "${usage}" 
        exit 
        ;;
    esac
done

SECLISTS_WEBCONTENT="/usr/share/seclists/Discovery/Web-Content"
DOWNLOADED_WORDLISTS="/etc/downloaded-wordlists"

case "$ffuf_wordlist_type" in
    "custom")
        if [ -z "${ffuf_custom_wordlist_file_name}" ]; then
            echo "ffuf_custom_wordlist_file_name: ${ffuf_custom_wordlist_file_name} needs to be defined, but it isn't."
            exit 1
        fi
        if [ ! -f "${ffuf_custom_wordlist_file_name}" ]; then
            echo "ffuf_custom_wordlist_file_name: ${ffuf_custom_wordlist_file_name} does not exist."
            exit 1
        fi
        combined_wordlist=$(cat "${ffuf_custom_wordlist_file_name}")
        ;;

    "small-api")
        # wc -l: 958872
        combined_wordlist=$(cat $DOWNLOADED_WORDLISTS/swagger-wordlist.txt)
        ;;

    "small-content")
        # wc -l: 30000
        combined_wordlist=$(cat $SECLISTS_WEBCONTENT/raft-medium-directories.txt)
        ;;

    "small-content+api")
        # make sure leading slash is removed
        # include api wordlists
        # wc -l: 988872
        combined_wordlist=$(cat $SECLISTS_WEBCONTENT/raft-medium-directories.txt $DOWNLOADED_WORDLISTS/swagger-wordlist.txt)
        ;;

    "big-api")
        # wc -l: 2138606
        combined_wordlist=$(cat $DOWNLOADED_WORDLISTS/httparchive_apiroutes_2020_11_20.txt $DOWNLOADED_WORDLISTS/httparchive_apiroutes_2021_11_28.txt $DOWNLOADED_WORDLISTS/swagger-wordlist.txt)
        ;;

    "big-content")
        # wc -l: 2588420
        combined_wordlist=$(cat $SECLISTS_WEBCONTENT/raft-medium-directories.txt $SECLISTS_WEBCONTENT/directory-list-2.3-big.txt $SECLISTS_WEBCONTENT/directory-list-lowercase-2.3-big.txt $SECLISTS_WEBCONTENT/raft-large-directories.txt $SECLISTS_WEBCONTENT/raft-large-files.txt)
        ;;

    "big-content+api")
        # wc -l: 4727026
        combined_wordlist=$(cat $SECLISTS_WEBCONTENT/raft-medium-directories.txt $SECLISTS_WEBCONTENT/directory-list-2.3-big.txt $SECLISTS_WEBCONTENT/directory-list-lowercase-2.3-big.txt $SECLISTS_WEBCONTENT/raft-large-directories.txt $SECLISTS_WEBCONTENT/raft-large-files.txt $DOWNLOADED_WORDLISTS/httparchive_apiroutes_2020_11_20.txt $DOWNLOADED_WORDLISTS/httparchive_apiroutes_2021_11_28.txt $DOWNLOADED_WORDLISTS/swagger-wordlist.txt) 
        ;;

    *)
        echo "[!] ${ffuf_wordlist_type} is not a valid type of intensity. Exiting."
        exit 1
        ;;
esac

echo "${combined_wordlist}"  | sed -e 's/^\///' | sort -u > combined_wordlist.txt
wc -l combined_wordlist.txt

if [ ! -z "${ffuf_wordlist_min_max_range}" ]; then
    echo "ffuf_wordlist_min_max_range: ${ffuf_wordlist_min_max_range}"
    cat combined_wordlist.txt | sed -n "${ffuf_wordlist_min_max_range}p" > combined_wordlist.tmp.txt
    rm combined_wordlist.txt
    mv combined_wordlist.tmp.txt combined_wordlist.txt
    wc -l combined_wordlist.txt
fi
