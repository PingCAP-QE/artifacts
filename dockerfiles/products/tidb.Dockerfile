ARG BASE_IMG=hub.pingcap.net/bases/tidb-base:v1.7.0
FROM $BASE_IMG
COPY tidb-server /tidb-server
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
