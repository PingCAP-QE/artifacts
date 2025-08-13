ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pingcap-base:v1.9.2
# ---- Base stage: shared setup, permissions, and runtime instructions ----
FROM $BASE_IMG as base

COPY tiproxy tiproxyctl /bin/
COPY conf/* /etc/proxy/
RUN chmod 755 /bin/tiproxy /bin/tiproxyctl && chmod 644 /etc/proxy/proxy.toml
EXPOSE 3080
EXPOSE 3081
EXPOSE 6000
ENTRYPOINT ["/bin/tiproxy", "-conf", "/etc/proxy/proxy.toml"]

# ---- Non-root stage: create and switch to pingcap user ----
FROM base as nonroot
RUN groupadd -g 2000 pingcap && \
    useradd -u 1000 -g 2000 -m pingcap
USER pingcap:pingcap

# ---- Root stage: default, runs as root ----
FROM base as root
