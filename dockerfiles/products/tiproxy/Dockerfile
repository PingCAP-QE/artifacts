ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.9.1
FROM $BASE_IMG

COPY tiproxy tiproxyctl /bin/
COPY conf/* /etc/proxy/

EXPOSE 3080
EXPOSE 3081
EXPOSE 6000

ENTRYPOINT ["/bin/tiproxy", "-conf", "/etc/proxy/proxy.toml"]
