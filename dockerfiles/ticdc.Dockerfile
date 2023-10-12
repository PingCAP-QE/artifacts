FROM hub.pingcap.net/bases/tools-base:v1.7.0
COPY cdc /cdc
EXPOSE 8300

CMD ["/cdc"]
