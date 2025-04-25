ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tikv-base:v1.9.2
FROM $BASE_IMG
COPY tikv-server /tikv-server
COPY cse-ctl /cse-ctl
COPY tikv-worker /tikv-worker
EXPOSE 20160 20180
ENTRYPOINT ["/tikv-server"]
