############## linux/amd64 ##################
FROM pingcap/alpine-glibc:alpine-3.14.6 AS amd64
ADD https://github.com/golang/go/raw/go1.22.5/lib/time/zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip

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
ADD https://github.com/golang/go/raw/go1.23.1/lib/time/zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip
