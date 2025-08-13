# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.10.0
FROM $BASE_IMG
COPY dm-worker /dm-worker
COPY dm-master /dm-master
COPY dmctl /dmctl
RUN chmod 755 /dm-worker /dm-master /dmctl
EXPOSE 8291 8261 8262
