ARG PINGCAP_BASE
FROM $PINGCAP_BASE
RUN dnf install -y bind-utils wget nc \
    && dnf clean all \
    && rm -rf /var/cache/yum
