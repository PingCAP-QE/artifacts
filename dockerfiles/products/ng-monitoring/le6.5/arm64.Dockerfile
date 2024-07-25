FROM pingcap/centos-stream:8
ADD https://github.com/golang/go/raw/go1.22.5/lib/time/zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip

COPY ng-monitoring-server /ng-monitoring-server
EXPOSE 12020
ENTRYPOINT ["/ng-monitoring-server"]
