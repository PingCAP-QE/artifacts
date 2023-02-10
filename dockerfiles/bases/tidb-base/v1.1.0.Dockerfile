# hub.pingcap.net/bases/tidb-base
FROM hub.pingcap.net/bases/pingcap-base:v1.1.0
RUN dnf install -y curl && dnf clean all
