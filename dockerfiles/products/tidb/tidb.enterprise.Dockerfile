# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tidb-base:v1.10.1
FROM $BASE_IMG
COPY --chmod=755 tidb-server /tidb-server
COPY --chmod=755 audit-1.so whitelist-1.so /plugins/
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
