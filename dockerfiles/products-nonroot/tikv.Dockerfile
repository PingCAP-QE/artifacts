FROM hub.pingcap.net/bases/tikv-base:v1.6.0
RUN adduser nonroot
USER nonroot
COPY tikv-server /tikv-server
COPY tikv-ctl /tikv-ctl
ENV MALLOC_CONF="prof:true,prof_active:false"
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
