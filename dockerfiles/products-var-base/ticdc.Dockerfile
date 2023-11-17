ARG BASE=hub.pingcap.net/bases/tools-base:v1.7.0
FROM $BASE
COPY cdc /cdc
EXPOSE 8300

CMD ["/cdc"]
