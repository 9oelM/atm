#!/bin/bash
# https://circleci.com/docs/2.0/using-shell-scripts/
# Exit script if a statement returns a non-true return value.
set -o errexit
# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o 
cat <<EOF
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

install.sh

- this script requires running as sudo.
- it installs atm-*.sh scripts to /usr/local/bin/atm. check if you have anything there already
- it DOES NOT install required binaries. you need to install them yourself. more details in README.md

EOF
# to be used inside github actions only
CUSTOM_PWD="$1"

echo "CUSTOM_PWD: ${CUSTOM_PWD}"

# if nothing came in as an input, replace it with '.'
[ -z "${CUSTOM_PWD}" ] && CUSTOM_PWD="."
# works only if called from the same dir
sudo mkdir -p "/usr/local/bin/atm"
sudo chmod ugo+x "${CUSTOM_PWD}"/atm*.{sh,py} 
sudo cp -nf "${CUSTOM_PWD}"/atm*.{sh,py} "/usr/local/bin/atm/"
sudo cp "${CUSTOM_PWD}/.atm.version" "/usr/local/bin/atm/"
sudo chmod ugo+x /usr/local/bin/atm/atm*.{sh,py} 

echo "[+] Installation successful."
echo "[+] To use the scripts, add the following line to your shell config like .bashrc:"
echo "" 
echo "    PATH=\"\$PATH:/usr/local/bin/atm\"" 
echo "" 
echo "    and source your shell config to use it directly." 
