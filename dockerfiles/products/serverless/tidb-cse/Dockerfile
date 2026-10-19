FROM hub.pingcap.net/keyspace/builder/debian:bullseye-slim@sha256:acc5810124f0929ab44fc7913c0ad936b074cbd3eadf094ac120190862ba36c4
RUN apt-get update && apt-get install -y --no-install-recommends bash curl netcat dumb-init \
    && rm /bin/sh && ln -s /bin/bash /bin/sh && rm -rf /var/lib/apt/lists/*
COPY tidb-server /tidb-server
WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/usr/bin/dumb-init", "/tidb-server"]
