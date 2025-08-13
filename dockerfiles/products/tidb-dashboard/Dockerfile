ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pd-base:v1.10.0
FROM $BASE_IMG
COPY tidb-dashboard /tidb-dashboard
RUN chmod 755 /tidb-dashboard
EXPOSE 12333
ENTRYPOINT ["/tidb-dashboard"]
