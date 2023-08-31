# docker build . -t hub.pingcap.net/jenkins/centos-stream:8
FROM centos:8
# jq is only for pd
RUN set -e && \
    mkdir /tmp/package && cd /tmp/package && \
    curl -O 'http://mirror.centos.org/centos/8/extras/x86_64/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm' && \
    rpm -i 'centos-gpg-keys-8-3.el8.noarch.rpm' && \
    dnf -y --disablerepo '*' --enablerepo=extras swap centos-linux-repos centos-stream-repos && \
    dnf update -y bind-export-libs cyrus-sasl-lib expat glib2 gnutls nettle systemd systemd-libs systemd-pam systemd-udev zlib \
    https://dl.rockylinux.org/pub/rocky/8/BaseOS/aarch64/os/Packages/g/gzip-1.9-13.el8_5.aarch64.rpm \
    https://dl.rockylinux.org/pub/rocky/8/BaseOS/aarch64/os/Packages/x/xz-5.2.4-4.el8_6.aarch64.rpm \
    https://dl.rockylinux.org/pub/rocky/8/BaseOS/aarch64/os/Packages/x/xz-libs-5.2.4-4.el8_6.aarch64.rpm \
    https://dl.rockylinux.org/pub/rocky/8/BaseOS/aarch64/os/Packages/l/libksba-1.3.5-9.el8_7.aarch64.rpm \
    https://dl.rockylinux.org/pub/rocky/8/BaseOS/aarch64/os/Packages/k/krb5-libs-1.18.2-22.el8_7.aarch64.rpm \
    https://dl.rockylinux.org/pub/rocky/8/BaseOS/aarch64/os/Packages/o/openssl-1.1.1k-9.el8_7.aarch64.rpm \
    https://dl.rockylinux.org/pub/rocky/8/BaseOS/aarch64/os/Packages/o/openssl-libs-1.1.1k-9.el8_7.aarch64.rpm \
    https://dl.rockylinux.org/pub/rocky/8/BaseOS/aarch64/os/Packages/p/python3-libs-3.6.8-51.el8_8.1.rocky.0.aarch64.rpm \
    https://dl.rockylinux.org/pub/rocky/8/BaseOS/aarch64/os/Packages/p/platform-python-3.6.8-51.el8_8.1.rocky.0.aarch64.rpm \
    && \
    dnf install bind-utils wget nmap jq -y && \
    cd / && rm -Rf /tmp/package && \
    dnf clean all
