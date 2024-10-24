ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tiflash-base:v1.0.1-old
FROM $BASE_IMG
ENV LD_LIBRARY_PATH /tiflash
COPY tiflash /tiflash
ENTRYPOINT ["/tiflash/tiflash", "server"]
