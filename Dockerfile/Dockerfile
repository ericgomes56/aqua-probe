FROM centos:7.9.2009

COPY repo.txt /tmp/repo.txt

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
        sed 's|vault.centos.org/7.9.2009|vault.centos.org/altarch/7.9.2009|g' /tmp/repo.txt > /etc/yum.repos.d/CentOS-Base.repo; \
    else \
        cat /tmp/repo.txt > /etc/yum.repos.d/CentOS-Base.repo; \
    fi && \
    rm -f /tmp/repo.txt

RUN yum clean all && \
    yum makecache && \
    yum install -y git wget tar gcc make nmap-ncat && \
    yum clean all

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then GOARCH=arm64; else GOARCH=amd64; fi && \
    wget --no-check-certificate https://go.dev/dl/go1.21.4.linux-${GOARCH}.tar.gz && \
    tar -C /usr/local -xzf go1.21.4.linux-${GOARCH}.tar.gz && \
    rm -f go1.21.4.linux-${GOARCH}.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

RUN git -c http.sslVerify=false clone https://github.com/guitmz/memrun.git /tmp/memrun

WORKDIR /tmp/memrun
RUN go build memrun.go

WORKDIR /

RUN mv /tmp/memrun/memrun /tmp/memrun.bin && \
    rm -rf /tmp/memrun && \
    mv /tmp/memrun.bin /tmp/memrun && \
    chmod +x /tmp/memrun

COPY target.c /tmp/target.c

RUN gcc /tmp/target.c -o /tmp/target && \
    rm -f /tmp/target.c
