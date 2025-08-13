# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.10.0
FROM $BASE_IMG
COPY br /br
RUN chmod 755 /br
CMD ["/br"]
