ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pd-base:v1.9.1
FROM $BASE_IMG
COPY tidb-dashboard /tidb-dashboard
EXPOSE 12333
ENTRYPOINT ["/tidb-dashboard"]
