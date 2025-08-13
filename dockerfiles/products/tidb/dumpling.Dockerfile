# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.10.0
FROM $BASE_IMG
COPY dumpling /dumpling
RUN chmod 755 /dumpling
CMD ["/dumpling"]
