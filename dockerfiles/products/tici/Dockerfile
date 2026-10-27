# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.12.5
FROM $BASE_IMG
COPY --chmod=755 tici-server /

ENTRYPOINT ["/tici-server"]
