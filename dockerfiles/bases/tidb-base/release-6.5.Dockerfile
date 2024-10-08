############## linux/amd64 ##################
FROM pingcap/alpine-glibc:alpine-3.14.6 AS amd64
RUN apk add --no-cache curl

############## linux/arm64 ##################
FROM pingcap/centos-stream:8 AS arm64
# CentOS 7,8 has reached EOL
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo \
    && _date=20240919 dnf upgrade -y && dnf clean all \
    && sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
RUN set -e && \
    dnf install bind-utils curl nmap-ncat -y && \
    dnf clean all
