FROM pingcap/centos-stream:8
COPY zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip

COPY pump /pump
COPY drainer /drainer
COPY reparo /reparo
COPY binlogctl /binlogctl
EXPOSE 4000
EXPOSE 8249 8250
CMD ["/pump"]
