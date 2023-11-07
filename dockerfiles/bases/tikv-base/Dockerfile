# hub.pingcap.net/bases/tikv-base:v1.7.0
# hub.pingcap.net/bases/tikv-base:v1.7
# hub.pingcap.net/bases/tikv-base:v1
ARG PINGCAP_BASE
FROM $PINGCAP_BASE
# wget is requested by operator
RUN dnf install -y tzdata wget && dnf clean all
ENV TZ=/etc/localtime \
    TZDIR=/usr/share/zoneinfo
