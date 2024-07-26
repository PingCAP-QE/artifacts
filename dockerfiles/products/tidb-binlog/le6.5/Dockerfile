ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.0.0-old
FROM $BASE_IMG
COPY pump /pump
COPY drainer /drainer
COPY reparo /reparo
COPY binlogctl /binlogctl
EXPOSE 4000
EXPOSE 8249 8250
CMD ["/pump"]
