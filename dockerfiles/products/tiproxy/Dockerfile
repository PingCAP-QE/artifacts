ARG BASE_IMG=hub.pingcap.net/bases/pingcap-base:v1.8.0
FROM $BASE_IMG

COPY --from=builder tiproxy tiproxyctl /bin/
COPY --from=builder conf/* /etc/proxy/

EXPOSE 3080
EXPOSE 3081
EXPOSE 6000

ENTRYPOINT ["/bin/tiproxy", "-conf", "/etc/proxy/proxy.toml"]
