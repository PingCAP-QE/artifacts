ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tiflash-base:v1.10.0
FROM $BASE_IMG
ENV LD_LIBRARY_PATH /tiflash
COPY tiflash /tiflash
# Enable jemalloc profiling, inactive by default.
# See https://jemalloc.net/jemalloc.3.html for details.
ENV MALLOC_CONF="prof:true,prof_active:false"
RUN chmod -R 755 /tiflash
ENTRYPOINT ["/tiflash/tiflash", "server"]
