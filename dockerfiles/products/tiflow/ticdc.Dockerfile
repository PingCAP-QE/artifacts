# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.11.1
FROM $BASE_IMG
COPY --chmod=755 cdc /cdc
EXPOSE 8300
CMD ["/cdc"]
