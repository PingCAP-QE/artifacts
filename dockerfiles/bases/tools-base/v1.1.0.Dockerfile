# hub.pingcap.net/bases/net-base
FROM hub.pingcap.net/bases/pingcap-base:v1.1.0
RUN dnf install -y bind-utils wget nc && dnf clean all
