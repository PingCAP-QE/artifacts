############## linux/amd64 ##################
FROM pingcap/alpine-glibc:alpine-3.14.6 AS amd64
# set timezone
ENV TZ=/etc/localtime
ENV TZDIR=/usr/share/zoneinfo

############## linux/arm64 ##################
FROM pingcap/centos-stream:8 AS arm64
# CentOS 7,8 has reached EOL
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
# set timezone
ENV TZ=/etc/localtime
ENV TZDIR=/usr/share/zoneinfo
