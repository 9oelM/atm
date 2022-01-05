# Content discovery

1. find subdomains
1. `atm-run-preliminary-ffuf.sh`
1. `atm-monkeypatch-ffuf-csv-output.sh`
1. `atm-process-ffuf-csv-output.sh`

# Javascript recon

1. find subdomains
1. `atm-find-urls.sh`
1. `atm-find-ext-urls.sh -e js`
1. `atm-download-files-from-urls.sh`
1. `atm-find-non-binary-files.sh`
1. `atm-beautify-js.sh`
1. `atm-find-words-from-files.sh`

# CRLF test

1. find subdomains
1. `atm-find-location-reflected-urls.sh`
1. `atm-generate-crlf-injection-payloads.sh`
1. `atm-find-crlf-injections.sh`