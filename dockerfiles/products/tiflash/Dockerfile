ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tiflash-base:v1.9.2

# ---- Base stage: shared for both root and non-root images ----
FROM $BASE_IMG as base
ENV LD_LIBRARY_PATH /tiflash
COPY tiflash /tiflash
# Enable jemalloc profiling, inactive by default.
# See https://jemalloc.net/jemalloc.3.html for details.
ENV MALLOC_CONF="prof:true,prof_active:false"
RUN chmod -R 755 /tiflash
ENTRYPOINT ["/tiflash/tiflash", "server"]

# ---- Non-root image stage ----
FROM base as nonroot
RUN groupadd -g 2000 pingcap && \
    useradd -u 1000 -g 2000 -m pingcap
USER pingcap:pingcap

# ---- Root image stage (default) ----
FROM base as root
