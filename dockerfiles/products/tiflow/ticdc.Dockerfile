# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.10.0
FROM $BASE_IMG
COPY cdc /cdc
RUN chmod 755 /cdc
EXPOSE 8300
CMD ["/cdc"]
