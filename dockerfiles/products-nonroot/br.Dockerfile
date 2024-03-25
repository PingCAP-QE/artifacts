FROM hub.pingcap.net/bases/pingcap-base:v1.6.0
RUN adduser nonroot
USER nonroot
COPY br /br
