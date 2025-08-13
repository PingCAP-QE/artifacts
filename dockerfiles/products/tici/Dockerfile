ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.9.2

# ---- Base stage: shared for both root and non-root images ----
FROM $BASE_IMG as base

COPY meta_service_server worker_node_server /app/

ENTRYPOINT ["/app/meta_service_server"]
# TODO: maybe we should split it into two images.

# ---- Non-root image stage ----
FROM base as nonroot
RUN groupadd -g 2000 pingcap && \
    useradd -u 1000 -g 2000 -m pingcap
USER pingcap:pingcap

# ---- Root image stage (default) ----
FROM base as root
