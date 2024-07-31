ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.9.1
FROM $BASE_IMG
COPY tidb-lightning /tidb-lightning
COPY tidb-lightning-ctl /tidb-lightning-ctl
