# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.10.0
FROM $BASE_IMG
COPY meta_service_server worker_node_server /app/
RUN chmod 755 /app/meta_service_server /app/worker_node_server

ENTRYPOINT ["/app/meta_service_server"]
