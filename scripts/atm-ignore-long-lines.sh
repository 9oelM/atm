#!/bin/bash

[ ! -z "$1" ] && MAX_LINE_LENGTH="$1"
# greps reasonably formatted wordlists mainly for parameter bruteforcing
stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input into this script."
    echo "example: cat containslonglines.txt | atm-ignore-long-lines.sh 1000"
    echo "[!] No stdin detected. Pipe input into this script."
    exit
fi

echo "${stdin}"  | sed -e "/^.\{${MAX_LINE_LENGTH}\}./d"
