ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.0.1-old
FROM $BASE_IMG

COPY tidb-lightning /tidb-lightning
COPY tidb-lightning-ctl /tidb-lightning-ctl
COPY br /br
