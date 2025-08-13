# syntax=docker/dockerfile:1

ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tikv-base:v1.9.2
FROM $BASE_IMG as base
COPY tikv-server /tikv-server
COPY cse-ctl /cse-ctl
COPY tikv-worker /tikv-worker
RUN chmod 755 /tikv-server /cse-ctl /tikv-worker
ENV MALLOC_CONF="prof:true,prof_active:false"
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]

# Non-root image stage
FROM base as nonroot
RUN groupadd -g 2000 pingcap && \
    useradd -u 1000 -g 2000 -m pingcap
USER pingcap:pingcap

# Root image stage (default)
FROM base as root

# Default build is root image.
# To build non-root: docker build --target nonroot -t tikv-next-gen:nonroot .
