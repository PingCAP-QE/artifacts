# hub.pingcap.net/bases/pd-base
FROM hub.pingcap.net/bases/pingcap-base:v1.1.0
RUN dnf install bind-utils wget -y && \
    dnf clean all
