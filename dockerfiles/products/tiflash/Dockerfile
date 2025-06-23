ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tiflash-base:v1.9.2
FROM $BASE_IMG
ENV LD_LIBRARY_PATH /tiflash
COPY tiflash /tiflash
# Enable jemalloc profiling, inactive by default.
# See https://jemalloc.net/jemalloc.3.html for details.
ENV MALLOC_CONF="prof:true,prof_active:false"
ENTRYPOINT ["/tiflash/tiflash", "server"]
