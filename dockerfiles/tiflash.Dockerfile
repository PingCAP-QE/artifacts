FROM hub.pingcap.net/bases/tiflash-base:v1.6.0
ENV LD_LIBRARY_PATH /tiflash
COPY tiflash /tiflash
ENTRYPOINT ["/tiflash/tiflash", "server"]
