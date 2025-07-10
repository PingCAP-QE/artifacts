ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.9.2
FROM $BASE_IMG

COPY meta_service_server worker_node_server /app/

ENTRYPOINT ["/app/meta_service_server"]
# TODO: maybe we should split it into two images.
