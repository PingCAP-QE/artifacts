FROM docker.io/library/debian:bullseye-slim@sha256:e5b6442dd2e9684cf5e87d8338b5968f3b348636fc0be6d7850a381e3731a2bd
# Keep the source image's runtime utilities and init process.
RUN sed -i '/debian-security/ s|deb.debian.org|archive.debian.org|' /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y --no-install-recommends ca-certificates bash curl netcat procps dumb-init \
    && rm /bin/sh && ln -s /bin/bash /bin/sh && rm -rf /var/lib/apt/lists/*
ENV BR_LOG_TO_TERM=1
COPY br /br
WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/usr/bin/dumb-init", "/br"]
