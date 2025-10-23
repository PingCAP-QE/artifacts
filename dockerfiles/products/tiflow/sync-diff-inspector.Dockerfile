# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.10.1
FROM $BASE_IMG
COPY --chmod=755 sync_diff_inspector /sync_diff_inspector
CMD ["/sync_diff_inspector"]
