FROM pingcap/alpine-glibc:alpine-3.14.6
ADD https://github.com/golang/go/raw/go1.22.5/lib/time/zoneinfo.zip /usr/local/go/lib/time/zoneinfo.zip

COPY pump /pump
COPY drainer /drainer
COPY reparo /reparo
COPY binlogctl /binlogctl
EXPOSE 4000
EXPOSE 8249 8250
CMD ["/pump"]
