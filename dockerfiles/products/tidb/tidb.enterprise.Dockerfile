# syntax=docker/dockerfile:1

ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tidb-base:v1.9.2
FROM $BASE_IMG as base

COPY tidb-server /tidb-server
COPY audit-1.so /plugins/audit-1.so
COPY whitelist-1.so /plugins/whitelist-1.so
RUN chmod 755 /tidb-server /plugins/audit-1.so /plugins/whitelist-1.so
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]

# Non-root image stage
FROM base as nonroot
RUN groupadd -g 2000 pingcap && \
    useradd -u 1000 -g 2000 -m pingcap
USER pingcap:pingcap

# Root image stage (default)
FROM base as root

# Default build is root image.
# To build non-root: docker build --target nonroot -t tidb-enterprise:nonroot .
