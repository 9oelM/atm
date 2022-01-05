#!/bin/bash
NEGATIVE_AND_POSITIVE_LOOKUP_CHARS="20"
ENABLE_NEGATIVE_AND_POSITIVE_LOOKUP="1"

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

atm-find-words-from-files.sh

finds specific words from text-based files and shows results.

example:
[1] Supply a wordlist: echo \"*.js\" | atm-find-words-from-files.sh -w secret-wordlist.txt
[2] Supply words inline: echo \"*.js\" | atm-find-words-from-files.sh -i \"secret_key api_key\"
[3] do both: echo \"*.js\" | atm-find-words-from-files.sh -w secret-wordlist.txt -i \"secret_key api_key\"
[4] write to file: echo \"*.js\" | atm-find-words-from-files.sh -i \"secret_key api_key\" | tee log.txt

by default, the match is case-insensitive.

usage:
-i [optional] [string] regex for words to be found, each separated by |. at least one of this or -w option must be used
-w [optional] [string] wordlist to use. at least one of this or -i option must be used
-l [optional] [0|1] enable negative and positive lookups. otherwise, the regex is
                    going to be matched solely on the word itself.
                    for example, if the word is 'secret' and -l option is 0,
                    the resulting regex will be: ^secret$.
                    if -l option is 1, the regex will be: .{0,${NEGATIVE_AND_POSITIVE_LOOKUP_CHARS}}(secret).{0,${NEGATIVE_AND_POSITIVE_LOOKUP_CHARS}}
              (default: ${ENABLE_NEGATIVE_AND_POSITIVE_LOOKUP}) 
-s [optional] [exact|line] how to show the match.
              exact shows only -${NEGATIVE_AND_POSITIVE_LOOKUP_CHARS} and +${NEGATIVE_AND_POSITIVE_LOOKUP_CHARS} chars around it  
              line shows the entire line that the matche belongs to.
              (default: line)  
-h help
"

HOW_TO_SHOW_THE_MATCH="line"
WORDLIST_PATH=""
INLINE_WORDS=""
while getopts w:s:i:l:h: flag; do
    case "${flag}" in
    w)
        WORDLIST_PATH=${OPTARG}
        ;;
    s)
        HOW_TO_SHOW_THE_MATCH=${OPTARG}
        ;;
    i)
        INLINE_WORDS=${OPTARG}
        ;;  
    l)
        ENABLE_NEGATIVE_AND_POSITIVE_LOOKUP=${OPTARG}
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

stdin=""
if [ -p /dev/stdin ]; then
    stdin="$(cat /dev/stdin)"
else
    echo "[!] No stdin detected. Pipe the file pattern into this script."
    echo "${usage}"
    echo "[!] No stdin detected. Pipe the file pattern into this script."
    exit
fi

if [ "${HOW_TO_SHOW_THE_MATCH}" != "line" ] && [ "${HOW_TO_SHOW_THE_MATCH}" != "exact" ]; then
    echo "[!] -s option should be either 'exact' or 'line'."
    echo "${usage}"
    echo "[!] -s option should be either 'exact' or 'line'."
    exit
fi

if [ "${ENABLE_NEGATIVE_AND_POSITIVE_LOOKUP}" != "0" ] && [ "${ENABLE_NEGATIVE_AND_POSITIVE_LOOKUP}" != "1" ]; then
    echo "[!] -l option should be either '0' or '1'."
    echo "${usage}"
    echo "[!] -l option should be either '0' or '1'."
    exit
fi

# if both don't exist
if [ ! -f "$WORDLIST_PATH" ] && [ -z "${INLINE_WORDS}" ]; then
    echo "[!] You need to supply a wordlist path with -w flag or a list of words inline with -i flag."
    echo "${usage}"
    echo "[!] You need to supply a wordlist path with -w flag or a list of words inline with -i flag."
    exit
fi

if [ -f "${WORDLIST_PATH}" ]; then
    # word_1\nword_2\nword_3 ... -> word_1|word_2|word_3
    WORDLIST_REGEX=$(cat "${WORDLIST_PATH}" | awk NF | sed -z 's/\n/\|/g;s/.$//')
fi

if [ ! -z "${INLINE_WORDS}" ]; then
    # temporarily allow this
    INLINE_WORDS_REGEX=$(echo "${INLINE_WORDS}")
    # INLINE_WORDS_REGEX=$(echo "${INLINE_WORDS}" | tr -s ' ' | sed -e 's/ /\|/g')
    # word_1 word_2 word_3 --> word_1|word_2|word_3
fi

if [ ! -z "${WORDLIST_REGEX}" ] && [ ! -z "${INLINE_WORDS_REGEX}" ]; then
    COMBINED_REGEX="${WORDLIST_REGEX}|${INLINE_WORDS_REGEX}"

    echo "${COMBINED_REGEX}"
elif [ ! -z "${WORDLIST_REGEX}" ]; then
    COMBINED_REGEX="${WORDLIST_REGEX}"
elif [ ! -z "${INLINE_WORDS_REGEX}" ]; then
    COMBINED_REGEX="${INLINE_WORDS_REGEX}"
else
    echo "[!] You need to supply a wordlist path with -w flag or a list of words inline with -i flag."
    echo "${usage}"
    echo "[!] You need to supply a wordlist path with -w flag or a list of words inline with -i flag."
    exit
fi

if [ "${ENABLE_NEGATIVE_AND_POSITIVE_LOOKUP}" == "1" ]; then
    FINAL_REGEX=".{0,${NEGATIVE_AND_POSITIVE_LOOKUP_CHARS}}(${COMBINED_REGEX}).{0,${NEGATIVE_AND_POSITIVE_LOOKUP_CHARS}}"
elif [ "${ENABLE_NEGATIVE_AND_POSITIVE_LOOKUP}" == "0" ]; then
    FINAL_REGEX="^(${COMBINED_REGEX})$"
else
    echo "[!] -l option should be either '0' or '1'."
    echo "${usage}"
    echo "[!] -l option should be either '0' or '1'."
    exit
fi

echo "[+] First 100 characters of generated regex:"
echo "    ${FINAL_REGEX}" | head -c 100
echo "[+] Now proceeding to scan"

BASIC_GREP_FLAGS="--color=always --with-filename --ignore-case --line-number"
FINAL_GREP_FLAGS=""
if [ "${HOW_TO_SHOW_THE_MATCH}" == "line" ]; then
    FINAL_GREP_FLAGS="${BASIC_GREP_FLAGS}"
elif [ "${HOW_TO_SHOW_THE_MATCH}" == "exact" ]; then 
    FINAL_GREP_FLAGS="${BASIC_GREP_FLAGS} --only-matching"
else
    echo "[!] -s option should be either 'exact' or 'line'."
    echo "${usage}"
    echo "[!] -s option should be either 'exact' or 'line'."
    exit
fi

if [ "${ENABLE_NEGATIVE_AND_POSITIVE_LOOKUP}" == "1" ]; then
    FINAL_GREP_FLAGS="${FINAL_GREP_FLAGS} -E"
elif [ "${ENABLE_NEGATIVE_AND_POSITIVE_LOOKUP}" == "0" ]; then
    # enable regular expression to match the exact word
    FINAL_GREP_FLAGS="${FINAL_GREP_FLAGS} -P"
else
    echo "[!] -l option should be either '0' or '1'."
    echo "${usage}"
    echo "[!] -l option should be either '0' or '1'."
    exit
fi
echo "[+] Running 'grep ${FINAL_GREP_FLAGS} ${FINAL_REGEX} $stdin'"
# no quotes around stdin. otherwise errors
command="echo \"${stdin}\" | xargs -P 10 grep ${FINAL_GREP_FLAGS} \"${FINAL_REGEX}\""
bash -c "${command};"

echo "[+] Done"