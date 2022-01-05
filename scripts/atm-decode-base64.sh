#!/bin/bash

# decodes multiple lines in base64 

stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input into this script."
    echo "${usage}"
    echo "[!] No stdin detected. Pipe input into this script."
    exit
fi

echo -n "${stdin}" | xargs -I{} bash -c 'result=$(base64 --decode <<< {}); echo "${result}"'