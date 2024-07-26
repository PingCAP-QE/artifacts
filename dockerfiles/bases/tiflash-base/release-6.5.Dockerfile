FROM centos:7.9.2009

# CentOS 7 has reached EOL
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo

# Update packages
RUN yum update -y bind-license cyrus-sasl-lib expat glib2 gzip krb5-libs openssl-libs systemd systemd-libs xz xz-libs zlib nss nss-sysinit nss-tools

# Set timezone
ENV TZ Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone
