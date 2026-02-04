# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tidb-base:v1.11.1
FROM $BASE_IMG
COPY --chmod=755 tidb-server /tidb-server
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
