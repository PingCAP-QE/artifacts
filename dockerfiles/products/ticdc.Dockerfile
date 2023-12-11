ARG BASE_IMG=hub.pingcap.net/bases/tools-base:v1.8.0
FROM $BASE_IMG
COPY cdc /cdc
EXPOSE 8300

CMD ["/cdc"]
