ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pd-base:v1.11.1
FROM $BASE_IMG
COPY --chmod=755 tidb-dashboard /tidb-dashboard
EXPOSE 12333
ENTRYPOINT ["/tidb-dashboard"]
