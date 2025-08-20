ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tidb-base:v1.10.0
FROM $BASE_IMG
COPY tidb-server /tidb-server
COPY audit-1.so /plugins/audit-1.so
COPY whitelist-1.so /plugins/whitelist-1.so
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
