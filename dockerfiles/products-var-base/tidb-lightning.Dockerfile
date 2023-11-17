ARG BASE=hub.pingcap.net/bases/tools-base:v1.7.0
FROM $BASE
COPY tidb-lightning /tidb-lightning
COPY tidb-lightning-ctl /tidb-lightning-ctl
