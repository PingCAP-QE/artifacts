ARG BASE_IMG=hub.pingcap.net/bases/tiflash-base:v1.8.0
FROM $BASE_IMG
ENV LD_LIBRARY_PATH /tiflash
COPY tiflash /tiflash
ENTRYPOINT ["/tiflash/tiflash", "server"]
