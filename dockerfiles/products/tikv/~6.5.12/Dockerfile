ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tikv-base:v1.9.2
FROM $BASE_IMG
COPY tikv-server /tikv-server
COPY tikv-ctl /tikv-ctl
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
