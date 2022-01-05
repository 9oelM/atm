#!/bin/bash
####################################################
# @9oelm
####################################################
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

atm-find-valid-urls.sh

outputs only valid urls from stdin
"

url_regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "${usage}"
    echo "[!] No stdin detected. Pipe input into this script."
    echo "    Example: cat myurls.txt | ./atm-find-valid-urls.sh"
fi

echo "${stdin}" | grep -E "${url_regex}"