# syntax=docker/dockerfile:1

ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.9.2
FROM $BASE_IMG as base

COPY sync_diff_inspector /sync_diff_inspector
RUN chmod 755 /sync_diff_inspector
CMD ["/sync_diff_inspector"]

# Non-root image stage
FROM base as nonroot
RUN groupadd -g 2000 pingcap && \
    useradd -u 1000 -g 2000 -m pingcap
USER pingcap:pingcap

# Root image stage (default)
FROM base as root

# Default build is root image.
# To build non-root: docker build --target nonroot -t sync-diff-inspector:nonroot .
