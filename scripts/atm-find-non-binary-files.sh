
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

atm-find-non-binary-files.sh

usage:
-d [optional] path to directory (default: '.')

finds files that are not binary files (i.e. plaintext files) in current working directory
also finds the ones in nested folders under current working directory.

example: atm-find-non-binary-files.sh | xargs cat
"
DIRECTORY="."
while getopts d:h: flag; do
    case "${flag}" in
    d)
        DIRECTORY=${OPTARG}
        ;;
    h)
        printf "$USAGE"
        exit
        ;;
    esac
done

[ ! -d "${DIRECTORY}" ] && echo "${DIRECTORY} does not exist." && printf "$USAGE" && echo "${DIRECTORY} does not exist." && exit 1

# only finds plaintext files (non binary files)
# https://unix.stackexchange.com/questions/46276/finding-all-non-binary-files
find "${DIRECTORY}" -type f -not -path '*/\.*' -exec grep -Il '.' {} \; | xargs -L 1 echo