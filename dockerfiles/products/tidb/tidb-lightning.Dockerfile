# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.10.0
FROM $BASE_IMG
COPY --chmod=755 tidb-lightning tidb-lightning-ctl /
EXPOSE 8289
ENTRYPOINT ["/tidb-lightning"]
