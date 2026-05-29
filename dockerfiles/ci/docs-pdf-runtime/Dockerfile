FROM pandoc/extra@sha256:07f33f3c77fdde0eede08e2e145de82a048f35ff3e642546cb6e85da9b414498

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description="Docs PDF runtime with pandoc, xelatex, rclone, and WenQuanYi fonts"
LABEL org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts"

COPY --from=rclone/rclone@sha256:9ce0d49b611d3781233e25334e9e23d7af01e5546da7087f90d55f034ef13637 /usr/local/bin/rclone /usr/local/bin/rclone

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates fonts-wqy-microhei; \
    rm -rf /var/lib/apt/lists/*; \
    fc-cache -fv >/dev/null || true

ENTRYPOINT ["/bin/bash", "-lc"]
