ARG BASE=hub.pingcap.net/bases/ng-monitoring-base:v1.7.0
FROM $BASE
COPY ng-monitoring-server /ng-monitoring-server
EXPOSE 12020
ENTRYPOINT ["/ng-monitoring-server"]
