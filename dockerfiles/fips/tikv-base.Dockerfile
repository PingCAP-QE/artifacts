# hub.pingcap.net/bases/tikv-base:v1-fips
FROM hub.pingcap.net/bases/pingcap-base:v1
# wget is requested by operator
RUN dnf install -y tzdata wget openssl && dnf clean all
ENV TZ=/etc/localtime \
    TZDIR=/usr/share/zoneinfo
