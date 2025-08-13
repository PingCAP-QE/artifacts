# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tidb-base:v1.10.0
FROM $BASE_IMG
COPY --chmod=755 tidb-server /tidb-server
COPY --chmod=755 audit-1.so /plugins/audit-1.so
COPY --chmod=755 whitelist-1.so /plugins/whitelist-1.so
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
