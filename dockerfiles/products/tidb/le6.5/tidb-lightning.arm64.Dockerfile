FROM pingcap/centos-stream:8
ADD https://github.com/golang/go/raw/go1.22.5/lib/time/zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip

COPY tidb-lightning /tidb-lightning
COPY tidb-lightning-ctl /tidb-lightning-ctl
COPY br /br
