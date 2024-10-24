ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tidb-base:v1.0.1-old
FROM $BASE_IMG
COPY tidb-server /tidb-server
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
