ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.10.0
FROM $BASE_IMG
COPY tiproxy tiproxyctl /bin/
COPY conf/* /etc/proxy/
RUN chmod 755 /bin/tiproxy /bin/tiproxyctl && chmod 644 /etc/proxy/proxy.toml
EXPOSE 3080 3081 6000
ENTRYPOINT ["/bin/tiproxy", "-conf", "/etc/proxy/proxy.toml"]
