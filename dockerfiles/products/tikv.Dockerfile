ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tikv-base:v1.9.0
FROM $BASE_IMG
COPY tikv-server /tikv-server
COPY tikv-ctl /tikv-ctl
ENV MALLOC_CONF="prof:true,prof_active:false"
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
