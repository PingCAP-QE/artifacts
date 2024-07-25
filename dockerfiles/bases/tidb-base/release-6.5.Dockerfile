# linux/amd64: https://github.com/PingCAP-QE/ci-dockerfile/blob/master/jenkins/amd64/alpine-3.14.6
FROM pingcap/alpine-glibc:alpine-3.14.6 AS amd64
RUN apk add --no-cache curl

# linux/arm64: https://github.com/PingCAP-QE/artifacts/blob/main/dockerfiles/old-bases/arm64/centos-stream.Dockerfile
FROM pingcap/centos-stream:8 AS arm64
# CentOS 7,8 has reached EOL
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo

RUN set -e && \
    dnf install bind-utils curl nmap-ncat -y && \
    dnf clean all
