ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tikv-base:v1.11.1
FROM $BASE_IMG
COPY --chmod=755 tikv-server tikv-ctl /
ENV MALLOC_CONF="prof:true,prof_active:false"
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
