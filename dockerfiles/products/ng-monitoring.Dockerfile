ARG BASE_IMG=hub.pingcap.net/bases/ng-monitoring-base:v1.8.0
FROM $BASE_IMG
COPY ng-monitoring-server /ng-monitoring-server
EXPOSE 12020
ENTRYPOINT ["/ng-monitoring-server"]
