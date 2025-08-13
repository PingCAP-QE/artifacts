# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.10.0
FROM $BASE_IMG
COPY --chmod=755 meta_service_server worker_node_server /app/

ENTRYPOINT ["/app/meta_service_server"]
