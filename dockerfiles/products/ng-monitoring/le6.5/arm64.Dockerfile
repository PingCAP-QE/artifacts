FROM pingcap/centos-stream:8
COPY zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip
COPY ng-monitoring-server /ng-monitoring-server
EXPOSE 12020
ENTRYPOINT ["/ng-monitoring-server"]
