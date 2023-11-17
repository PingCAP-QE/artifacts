ARG BASE=hub.pingcap.net/bases/tidb-base:v1.7.0
FROM $BASE
COPY tidb-server /tidb-server
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
