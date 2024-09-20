ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tiflow-base:v1.0.1-old
FROM $BASE_IMG

COPY dm-worker /dm-worker
COPY dm-master /dm-master
COPY dmctl /dmctl

EXPOSE 8291 8261 8262
