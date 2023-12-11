ARG BASE_IMG=hub.pingcap.net/bases/pd-base:v1.8.0
FROM $BASE_IMG
COPY pd-server /pd-server
COPY pd-ctl /pd-ctl
COPY pd-recover /pd-recover
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
