FROM pingcap/alpine-glibc:alpine-3.14.6
COPY zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip

COPY sync_diff_inspector /sync_diff_inspector