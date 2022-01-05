# should I use the snapshot release instead..?
FROM kalilinux/kali-rolling:latest

LABEL github="https://github.com/9oelM"
LABEL maintainer="9oelM"
LABEL version="0.0.1"
LABEL description="atm sandbox"

# https://github.com/moby/moby/issues/7281#issuecomment-389440503
SHELL ["/bin/bash", "-c"]
# https://github.com/cdr/code-server/issues/918#issuecomment-532791448
ENV SHELL /bin/bash

RUN apt-get update -y

RUN apt-get -y install openssl git jq python3-pip curl wget build-essential seclists parallel
RUN apt-get -y install sublist3r=1.1-0kali1 ffuf=1.3.1-0kali1 subfinder=2.3.8-0kali1 amass=3.15.0-0kali1
# install go
RUN curl -OL https://golang.org/dl/go1.17.4.linux-amd64.tar.gz
RUN tar -C /usr/local -xvf go1.17.4.linux-amd64.tar.gz
# idk why but go installs it at /root/go/bin
ENV PATH "$PATH:/usr/local/go/bin:/root/go/bin:$HOME/.cargo/bin"
RUN rm -rf go1.17.4.linux-amd64.tar.gz

# install dependencies for atm scripts
RUN go install github.com/mithrandie/csvq@v1.15.2
RUN go install github.com/lc/gau/v2/cmd/gau@v2.0.6
RUN go install github.com/hakluke/hakrawler@2.0
RUN go install github.com/projectdiscovery/httpx/cmd/httpx@v1.1.4
RUN go install github.com/tomnomnom/unfurl@v0.2.0
RUN go install github.com/tomnomnom/assetfinder@v0.1.1
# these don't have release tags
RUN go install github.com/003random/getJS@latest
RUN go install github.com/cgboal/sonarsearch/cmd/crobat@latest

RUN pip install -Iv jsbeautifier==1.14.0
RUN pip3 install -Iv yq==2.13.0

RUN git clone https://github.com/fabianonline/telegram.sh.git
RUN mv telegram.sh/telegram /usr/local/bin && chmod ugo+x /usr/local/bin/telegram && which telegram && rm -rf telegram.sh/telegram 

RUN mkdir -p /etc/downloaded-wordlists \ 
    # lines     file size
    # 953011	45.3mb
    && curl https://wordlists-cdn.assetnote.io/data/automated/httparchive_apiroutes_2020_11_20.txt -o /etc/downloaded-wordlists/httparchive_apiroutes_2020_11_20.txt \ 
    # 226723	6.5mb
    && curl https://wordlists-cdn.assetnote.io/data/automated/httparchive_apiroutes_2021_11_28.txt -o /etc/downloaded-wordlists/httparchive_apiroutes_2021_11_28.txt \
    # 958872	27.2mb
    && curl https://wordlists-cdn.assetnote.io/data/kiterunner/swagger-wordlist.txt -o /etc/downloaded-wordlists/swagger-wordlist.txt

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
    && source $HOME/.cargo/env \
    && cargo install xsv
RUN apt-get -y install miller=5.10.3-1

ENTRYPOINT ["/bin/bash"]
