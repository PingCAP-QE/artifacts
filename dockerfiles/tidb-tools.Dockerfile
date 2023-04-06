FROM hub.pingcap.net/bases/tools-base:v1.3.0
COPY sync_diff_inspector /sync_diff_inspector
CMD ["/sync_diff_inspector"]
