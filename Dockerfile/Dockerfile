FROM centos:7.9.2009

COPY repo.txt /tmp/repo.txt

RUN cat /tmp/repo.txt > /etc/yum.repos.d/CentOS-Base.repo && \
    rm -f /tmp/repo.txt

RUN yum clean all && \
    yum makecache && \
    yum install -y git wget tar gcc make nmap-ncat && \
    yum clean all

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then GOARCH=arm64; else GOARCH=amd64; fi && \
    wget https://go.dev/dl/go1.21.4.linux-${GOARCH}.tar.gz && \
    tar -C /usr/local -xzf go1.21.4.linux-${GOARCH}.tar.gz && \
    rm -f go1.21.4.linux-${GOARCH}.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

RUN git clone https://github.com/guitmz/memrun.git /tmp/memrun

WORKDIR /tmp/memrun
RUN go build memrun.go

WORKDIR /

RUN mv /tmp/memrun/memrun /tmp/memrun && \
    chmod +x /tmp/memrun && \
    rm -rf /tmp/memrun

COPY target.c /tmp/target.c

RUN gcc /tmp/target.c -o /tmp/target && \
    rm -f /tmp/target.c
