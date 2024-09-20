ARG PINGCAP_BASE
FROM $PINGCAP_BASE
# wget is requested by operator
RUN dnf install -y tzdata wget \
    && dnf clean all \
    && rm -rf /var/cache/yum
ENV TZ=/etc/localtime \
    TZDIR=/usr/share/zoneinfo
