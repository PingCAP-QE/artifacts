ARG BASE_IMG=hub.pingcap.net/bases/tools-base:v1.8.0
FROM $BASE_IMG
COPY sync_diff_inspector /sync_diff_inspector
