# hub.pingcap.net/bases/tikv-base:v1.6.0
# hub.pingcap.net/bases/tikv-base:v1.6
# hub.pingcap.net/bases/tikv-base:v1
FROM hub.pingcap.net/bases/pingcap-base:v1.6.0
# wget is requested by operator
RUN dnf install -y tzdata wget && dnf clean all
ENV TZ=/etc/localtime \
    TZDIR=/usr/share/zoneinfo
