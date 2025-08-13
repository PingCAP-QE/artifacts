# syntax=docker/dockerfile:1

ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.9.2
FROM $BASE_IMG as base

COPY dm-worker /dm-worker
COPY dm-master /dm-master
COPY dmctl /dmctl
RUN chmod 755 /dm-worker /dm-master /dmctl
EXPOSE 8291 8261 8262

# Non-root image stage
FROM base as nonroot
RUN groupadd -g 2000 pingcap && \
    useradd -u 1000 -g 2000 -m pingcap
USER pingcap:pingcap

# Root image stage (default)
FROM base as root

# Default build is root image.
# To build non-root: docker build --target nonroot -t dm:nonroot .
