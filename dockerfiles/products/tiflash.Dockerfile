ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tiflash-base:v1.9.2
FROM $BASE_IMG
ENV LD_LIBRARY_PATH /tiflash
COPY tiflash /tiflash
ENTRYPOINT ["/tiflash/tiflash", "server"]
