ARG PINGCAP_BASE=ghcr.io/pingcap-qe/bases/pingcap-base:v1.9.1
FROM $PINGCAP_BASE
# wget is requested by operator
RUN dnf install -y tzdata wget openssl \
    && dnf clean all \
    && rm -rf /var/cache/yum
ENV TZ=/etc/localtime \
    TZDIR=/usr/share/zoneinfo
