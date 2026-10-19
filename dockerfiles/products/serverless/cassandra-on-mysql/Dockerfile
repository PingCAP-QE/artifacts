FROM gcr.io/distroless/base-debian12:latest@sha256:fabbf1c0c357a3d42550111351daed089b20a2c954df13ee2fcff60602515e84
COPY proxy /cassandra-on-mysql-proxy
USER 65532:65532
WORKDIR /
# The orchestrator supplies the runtime command, as in the source repository.
