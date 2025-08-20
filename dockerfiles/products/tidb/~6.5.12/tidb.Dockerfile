ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tidb-base:v1.10.0
FROM $BASE_IMG
COPY tidb-server /tidb-server
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
