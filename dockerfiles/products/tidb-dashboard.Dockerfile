ARG BASE_IMG=hub.pingcap.net/bases/pd-base:v1.8.0
FROM $BASE_IMG
COPY tidb-dashboard /tidb-dashboard
EXPOSE 12333
ENTRYPOINT ["/tidb-dashboard"]
