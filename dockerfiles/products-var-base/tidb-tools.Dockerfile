ARG BASE=hub.pingcap.net/bases/tools-base:v1.7.0
FROM $BASE
COPY sync_diff_inspector /sync_diff_inspector
