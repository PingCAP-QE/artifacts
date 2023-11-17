ARG BASE=hub.pingcap.net/bases/pd-base:v1.7.0
FROM $BASE
COPY pd-server /pd-server
COPY pd-ctl /pd-ctl
COPY pd-recover /pd-recover
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
