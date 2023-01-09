FROM hub.pingcap.net/bases/tikv-base:v1.1.0
COPY tikv-server /tikv-server
COPY tikv-ctl /tikv-ctl
ENV MALLOC_CONF="prof:true,prof_active:false"
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
