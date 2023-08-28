FROM hub.pingcap.net/bases/tools-base:v1.6.0
RUN adduser nonroot
USER nonroot
COPY sync_diff_inspector /sync_diff_inspector
