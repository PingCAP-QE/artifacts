ARG BASE_IMG=ghcr.io/pingcap-qe/bases/ng-monitoring-base:v1.10.0
FROM $BASE_IMG
LABEL org.opencontainers.image.title="Next Generation Monitoring Server" \
    org.opencontainers.image.source="https://github.com/pingcap/ng-monitoring" \
    org.opencontainers.image.vendor="PingCAP Inc." \
    org.opencontainers.image.licenses="Apache-2.0"

COPY ng-monitoring-server /ng-monitoring-server
EXPOSE 12020
ENTRYPOINT ["/ng-monitoring-server"]
