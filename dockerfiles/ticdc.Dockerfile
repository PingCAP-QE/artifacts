FROM hub.pingcap.net/bases/tools-base:v1.6.0
COPY cdc /cdc
EXPOSE 8300

CMD ["/cdc"]
