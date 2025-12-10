ARG BASE_IMG=ghcr.io/pingcap-qe/bases/ng-monitoring-base:v1.11.0
FROM $BASE_IMG
COPY --chmod=755 ng-monitoring-server /ng-monitoring-server
EXPOSE 12020
ENTRYPOINT ["/ng-monitoring-server"]
