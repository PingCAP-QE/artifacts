ARG BASE=hub.pingcap.net/bases/tiflash-base:v1.7.0
FROM $BASE
ENV LD_LIBRARY_PATH /tiflash
COPY tiflash /tiflash
ENTRYPOINT ["/tiflash/tiflash", "server"]
