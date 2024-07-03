FROM pingcap/centos-stream:8
ENV TZ=/etc/localtime
ENV TZDIR=/usr/share/zoneinfo

COPY tikv-server /tikv-server
COPY tikv-ctl /tikv-ctl
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]