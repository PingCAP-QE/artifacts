FROM hub.pingcap.net/bases/tools-base:v1.6.0
RUN adduser nonroot
USER nonroot
COPY tidb-lightning /tidb-lightning
COPY tidb-lightning-ctl /tidb-lightning-ctl
COPY br /br
