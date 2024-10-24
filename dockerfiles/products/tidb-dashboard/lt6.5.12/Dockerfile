ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pd-base:v1.0.1-old
FROM $BASE_IMG
COPY tidb-dashboard /tidb-dashboard
EXPOSE 12333
ENTRYPOINT ["/tidb-dashboard"]
