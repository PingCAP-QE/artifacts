FROM pingcap/alpine-glibc:alpine-3.14.6
COPY zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip

COPY tidb-lightning /tidb-lightning
COPY tidb-lightning-ctl /tidb-lightning-ctl
COPY br /br
