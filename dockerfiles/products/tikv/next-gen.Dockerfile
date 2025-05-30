ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tikv-base:v1.9.2
FROM $BASE_IMG
COPY tikv-server /tikv-server
COPY cse-ctl /cse-ctl
COPY tikv-worker /tikv-worker
ENV MALLOC_CONF="prof:true,prof_active:false"
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
