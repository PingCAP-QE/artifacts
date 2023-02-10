# hub.pingcap.net/bases/tikv-base
FROM hub.pingcap.net/bases/pingcap-base:v1.1.0
RUN dnf install -y tzdata
ENV TZ=/etc/localtime
ENV TZDIR=/usr/share/zoneinfo
