ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pd-base:v1.9.2
FROM $BASE_IMG
COPY pd-server /pd-server
COPY pd-ctl /pd-ctl
COPY pd-recover /pd-recover
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
