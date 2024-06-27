ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.9.0
FROM $BASE_IMG
COPY sync_diff_inspector /sync_diff_inspector
