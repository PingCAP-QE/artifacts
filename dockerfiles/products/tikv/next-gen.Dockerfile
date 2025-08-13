# syntax=docker/dockerfile:1

ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tikv-base:v1.10.0
FROM $BASE_IMG
COPY --chmod=755 tikv-server /tikv-server
COPY --chmod=755 cse-ctl /cse-ctl
COPY --chmod=755 tikv-worker /tikv-worker
ENV MALLOC_CONF="prof:true,prof_active:false"
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
