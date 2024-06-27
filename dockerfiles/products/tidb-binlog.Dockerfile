ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tools-base:v1.9.0
FROM $BASE_IMG
COPY pump /pump
COPY drainer /drainer
COPY reparo /reparo
COPY binlogctl /binlogctl
EXPOSE 4000 8249 8250
CMD ["/pump"]
