ARG BASE_IMG=hub.pingcap.net/bases/tools-base:v1.7.0
FROM $BASE_IMG
COPY tidb-lightning /tidb-lightning
COPY tidb-lightning-ctl /tidb-lightning-ctl
COPY br /br
