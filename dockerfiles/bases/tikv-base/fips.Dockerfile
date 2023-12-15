# hub.pingcap.net/bases/tikv-base:v1-fips
ARG PINGCAP_BASE
FROM $PINGCAP_BASE
# wget is requested by operator
RUN dnf install -y tzdata wget openssl && dnf clean all
ENV TZ=/etc/localtime \
    TZDIR=/usr/share/zoneinfo
