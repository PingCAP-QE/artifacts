ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.11.1
FROM $BASE_IMG
COPY --chmod=755 cdc_storage_consumer /cdc_storage_consumer

ENTRYPOINT ["tail", "-f", "/dev/null"]
