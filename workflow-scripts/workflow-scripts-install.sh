#!/bin/bash
# https://circleci.com/docs/2.0/using-shell-scripts/

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

workflow-scripts-install.sh

- it installs workflow-scripts/atm-*.sh scripts to /usr/local/bin/atm-workflow-scripts. 
- this is meant for shell scripts to be used globally in github actions. you should use this script inside a github action.
- it DOES NOT install required binaries. you need to install them yourself. More details in README.md.

EOF

# to be used inside github actions only
CUSTOM_PWD="$1"
echo "CUSTOM_PWD: ${CUSTOM_PWD}"
# if nothing came in as an input, replace it with '.'
[ -z "${CUSTOM_PWD}" ] && CUSTOM_PWD="."
# works only if called from the same dir
mkdir -p "/usr/local/bin/atm-workflow-scripts"
chmod ugo+x "${CUSTOM_PWD}"/atm*.sh || true
cp -nf "${CUSTOM_PWD}"/atm*.sh "/usr/local/bin/atm-workflow-scripts/" || true
chmod ugo+x /usr/local/bin/atm-workflow-scripts/atm*.sh || true

echo "[+] Installation successful."
echo "[+] To use the scripts, add the following line to your shell config like .bashrc:"
echo "" 
echo "    PATH=\"\$PATH:/usr/local/bin/atm-workflow-scripts\"" 
echo "" 
echo "    and source your shell config to use it directly." 
