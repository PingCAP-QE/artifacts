ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.10.1
FROM $BASE_IMG
COPY --chmod=0755 tiproxy tiproxyctl /bin/
COPY --chmod=0644 conf/* /etc/proxy/
EXPOSE 3080 3081 6000
ENTRYPOINT ["/bin/tiproxy", "-conf", "/etc/proxy/proxy.toml"]
