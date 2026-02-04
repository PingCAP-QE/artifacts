ARG PINGCAP_BASE=ghcr.io/pingcap-qe/bases/pingcap-base:v1.11.1
FROM $PINGCAP_BASE
# wget is requested by operator
RUN dnf install -y tzdata wget openssl && dnf clean all
ENV TZ=/etc/localtime \
    TZDIR=/usr/share/zoneinfo
