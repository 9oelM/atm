#!/bin/bash

MAX_WORD_LENGTH="20"

[ ! -z "$1" ] && MAX_WORD_LENGTH="$1"
# greps reasonably formatted wordlists mainly for parameter bruteforcing
stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input into this script."
    echo "example: cat /usr/local/assetnote/httparchive_parameters_top_1m_2020_11_21.txt | grep -E (chat|incident|action|event|message) | atm-clean-words.sh 15"
    echo "[!] No stdin detected. Pipe input into this script."
    exit
fi

echo "${stdin}" | grep -Fv -e "[" -e "]" -e ")" -e "(" -e ";" -e "," -e "*" -e "?" -e "&" -e ":" -e "*" -e "." | sed -e "/^.\{${MAX_WORD_LENGTH}\}./d"
