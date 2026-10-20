FROM docker.io/library/debian:bullseye-slim@sha256:acc5810124f0929ab44fc7913c0ad936b074cbd3eadf094ac120190862ba36c4
RUN apt-get update && apt-get install -y --no-install-recommends jq bash curl dnsutils wget \
    && rm /bin/sh && ln -s /bin/bash /bin/sh && rm -rf /var/lib/apt/lists/*
COPY pd-server pd-ctl pd-recover /
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
