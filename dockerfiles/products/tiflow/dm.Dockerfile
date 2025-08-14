# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.10.0
FROM $BASE_IMG
COPY --chmod=755 dm-worker /dm-worker
COPY --chmod=755 dm-master /dm-master
COPY --chmod=755 dmctl /dmctl
EXPOSE 8291 8261 8262
