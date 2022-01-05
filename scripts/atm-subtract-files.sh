#!/bin/bash

file_to_be_subtracted="$1"
file_to_subtract_with="$2"

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

atm-subtract-files.sh

if the same line exists both in file_to_be_subtracted file_to_subtract_with, 
it is not going to be included in the output.
only lines that exist in file_to_be_subtracted and do not exist in file_to_subtract_with will
be included in the output.

usage: atm-subtract-files.sh file_to_be_subtracted file_to_subtract_with | tee soutput.txt
"

[ -z "${file_to_be_subtracted}" ] && printf "${usage}" && exit 1
[ -z "${file_to_subtract_with}" ] && printf "${usage}" && exit 1
[ ! -f "${file_to_be_subtracted}" ] && echo "${file_to_be_subtracted} does not exist." && printf "${usage}" && echo "${file_to_be_subtracted} does not exist."  && exit 1
[ ! -f "${file_to_subtract_with}" ] && echo "${file_to_subtract_with} does not exist." && printf "${usage}" && echo "${file_to_subtract_with} does not exist."  && exit 1

# https://stackoverflow.com/questions/18261352/how-to-subtract-the-two-files-in-linux
awk 'NR==FNR{a[$1];next}!($1 in a)' "${file_to_subtract_with}" "${file_to_be_subtracted}" 