# hub.pingcap.net/bases/pd-base:v1.7.0
# hub.pingcap.net/bases/pd-base:v1.7
# hub.pingcap.net/bases/pd-base:v1
ARG PINGCAP_BASE
FROM $PINGCAP_BASE
RUN dnf install bind-utils wget jq -y && \
    dnf clean all
