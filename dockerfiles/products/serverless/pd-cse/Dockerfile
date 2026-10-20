FROM docker.io/library/debian:bullseye-slim@sha256:acc5810124f0929ab44fc7913c0ad936b074cbd3eadf094ac120190862ba36c4
# Bullseye security packages have moved to the signed Debian archive.
RUN sed -i '/debian-security/ s|deb.debian.org|archive.debian.org|' /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y --no-install-recommends ca-certificates jq bash curl dnsutils wget \
    && rm /bin/sh && ln -s /bin/bash /bin/sh && rm -rf /var/lib/apt/lists/*
COPY pd-server pd-ctl pd-recover /
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
