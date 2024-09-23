ARG PINGCAP_BASE
FROM $PINGCAP_BASE
RUN dnf install --allowerasing -y wget \
    && dnf clean all \
    && rm -rf /var/cache/yum
