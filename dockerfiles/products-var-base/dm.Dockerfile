ARG BASE=hub.pingcap.net/bases/tools-base:v1.7.0
FROM $BASE
COPY dm-worker /dm-worker
COPY dm-master /dm-master
COPY dmctl /dmctl

EXPOSE 8291 8261 8262
