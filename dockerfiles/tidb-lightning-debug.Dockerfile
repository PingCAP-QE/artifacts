FROM hub.pingcap.net/bases/tools-base:v1.8.0
COPY tidb-lightning /tidb-lightning
COPY tidb-lightning-ctl /tidb-lightning-ctl
COPY br /br
