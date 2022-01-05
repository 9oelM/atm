# atm

```
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
```

A set of AuToMation scripts for hacking.

The biggest difference of this repo, from other mainstreams, is that it has each functionality in separate shell script, usable for different purposes.
The scripts don't have to run altogether, which would make the whole thing inflexible. Maybe you need to fuzz a single special target that you are concentrating on. Maybe there was something weird that you want to review again. Then you go into individual shell scripts.

# Prerequisites
## Install all tools used in the scripts

If you don't want to install them all in your local machine, you could run a docker container by building the image from the dockerfile provided in this repo. Otherwise, please reference the installation steps in Dockerfile if you are willing to directly install them in your local machine. 

# Installation

```bash
git clone https://github.com/9oelm/atm.git

cd scripts

chmod u+x install.sh

sudo ./install.sh 
```

# Scripts
```
atm-beautify-js.sh
atm-clean-words.sh
atm-decode-base64.sh
atm-download-files-from-urls.sh
atm-filter-csv-by-status-code.sh
atm-find-crlf-injections.sh
atm-find-ext-urls.sh
atm-find-location-reflected-urls.sh
atm-find-non-binary-files.sh
atm-find-quick-subdomains.sh
atm-find-target-subdomains.sh
atm-find-urls.sh
atm-find-valid-urls.sh
atm-find-words-from-files.sh
atm-find-working-urls.sh
atm-generate-crlf-injection-payloads.sh
atm-ignore-long-lines.sh
atm-monkeypatch-ffuf-csv-output.sh
atm-parse-target-yml.sh
atm-process-ffuf-csv-output.sh
atm-run-preliminary-ffuf.sh
atm-sanitize-wordlist.sh
atm-search-binaryedge.sh
atm-send-many-mails.py
atm-send-simple-mail.py
atm-subtract-files.sh
atm-unique-and-randomize-api-wordlist.sh
```

# Usage
Each shell script has its own -h (help) flag. Please look at `/scripts` directory.

# Expectations
- [x] Notify progress if `TELEGRAM_CHAT` and `TELEGRAM_TOKEN` are defined as environment variables (only in docker)
- [x] Automate creating payloads for and testing CRLF injection.
- [x] Automate javascript files scanning and sensitive information disclosure
- [x] Automate content discovery
- [ ] Automate finding reflected XSS 
- [ ] Automate finding prototype pollution
- [ ] Automate finding SQL injection
- [ ] Automate finding open redirect
- [ ] Automate finding http parameters using tools like https://github.com/s0md3v/Arjun

## Todo
- [ ] Integrate gospider into atm-find-urls.sh
- [ ] Docker build cache in Github actions

## Ref

### Wordlists
- https://github.com/cujanovic/Open-Redirect-Payloads/blob/master/Open-Redirect-payloads.txt
- https://github.com/omurugur/Open_Redirect_Payload_List/blob/master/Open-Redirect-Payload
- https://github.com/danielmiessler/SecLists/blob/master/Discovery/Variables/secret-keywords.txt
- https://github.com/m4ll0k/BBTz/blob/master/jsalert.py
- https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning
    use below code to get all slugs
    ```js
    const table = document.querySelector(`#article-contents > div > table:nth-child(21) > tbody`)
    [...table.children].map((tr) => [...tr.children][2].textContent).join('\n')
    ```
- https://gist.github.com/jhaddix/f64c97d0863a78454e44c2f7119c2a6a
- https://gist.github.com/jhaddix/b80ea67d85c13206125806f0828f4d10
- https://raw.githubusercontent.com/Bo0oM/fuzz.txt/master/fuzz.txt
- https://raw.githubusercontent.com/Bo0oM/fuzz.txt/master/extensions.txt
- https://gist.github.com/nullenc0de/96fb9e934fc16415fbda2f83f08b28e7#file-content_discovery_nullenc0de-txt
- https://gist.github.com/nullenc0de/9cb36260207924f8e1787279a05eb773
- https://wordlists.assetnote.io/

### Recon
- https://github.com/nahamsec/lazyrecon
- https://github.com/robotshell/magicRecon
- https://github.com/projectdiscovery/nuclei
- https://github.com/codingo/Reconnoitre
- https://github.com/six2dez/reconftw
- https://github.com/Tib3rius/AutoRecon
- https://github.com/003random/003Recon
