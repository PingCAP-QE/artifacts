FROM pingcap/centos-stream:8
COPY zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip

COPY br /br
