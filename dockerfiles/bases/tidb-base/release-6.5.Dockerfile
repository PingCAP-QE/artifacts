FROM pingcap/centos-stream:8
RUN set -e && \
    dnf install bind-utils curl nmap-ncat -y && \
    dnf clean all