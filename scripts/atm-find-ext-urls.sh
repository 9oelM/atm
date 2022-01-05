#!/bin/bash
####################################################
# @9oelm
####################################################

stdin=""
if [ -p /dev/stdin ]; then
    stdin=$(cat /dev/stdin)
else
    echo "[!] No stdin detected. Pipe input to this script. Example: cat mylinks.txt | ./atm-find-ext-urls.sh"
fi
EXTENSION=""

USAGE="
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

atm-find-ext-urls.sh

finds urls that end with a specific extension

usage:
-e [required] [string] extension to search for. example: js
-q [optional] [0|1] allow querystring in the file name. (default: 1) 
              for example, -e js -q 1 option will match test.js?a=a
              -e js option only will not match anything from test.js?a=a
	      this option will be useful in downloading some of the files found

example: cat list-of-links.txt | ./atm-find-ext-urls.sh -e js

https://somewhere.com/assets/js/main.js
https://somewhere.com/assets/js/bundle.js
...
"
ALLOW_QUERYSTRING=1

while getopts e:h:q: flag; do
    case "${flag}" in
    e)
        EXTENSION=${OPTARG}
        ;;
    q)
	ALLOW_QUERYSTRING=${OPTARG}
	;;
    h)
        printf "${USAGE}"
        exit
        ;;
    *) 
        printf "${USAGE}" 
        exit 
        ;;
    esac
done

[[ -z "${EXTENSION}" ]] && echo "[!] -e flag is not properly set. please try again." && echo "${USAGE}" && exit

REGEX='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
REGEX="${REGEX}\.${EXTENSION}"

if [[ "$ALLOW_QUERYSTRING" == "1" ]]; then
  REGEX="${REGEX}(\?[^\s\\]*)?"
else
  REGEX="${REGEX}$"
fi	

echo "${stdin}" | grep -Eo "${REGEX}"
