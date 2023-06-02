# hub.pingcap.net/bases/tikv-base:v1.5.1
# hub.pingcap.net/bases/tikv-base:v1.5
# hub.pingcap.net/bases/tikv-base:v1
FROM hub.pingcap.net/bases/pingcap-base:v1.5.0
# wget is for operator
RUN dnf install -y tzdata wget && dnf clean all
ENV TZ=/etc/localtime \
    TZDIR=/usr/share/zoneinfo
