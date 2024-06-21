ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tidb-base:v1.8.0-release-6.5
FROM $BASE_IMG
COPY tidb-server /tidb-server
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
