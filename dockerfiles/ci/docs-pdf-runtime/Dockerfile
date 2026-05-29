FROM pandoc/extra@sha256:dfae5cf73a0e0ad40acf23d2d2c4adf5715e560aeea3324aa87e68faaa2e70c9

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description="Docs PDF runtime with pandoc, xelatex, rclone, and WenQuanYi fonts"
LABEL org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts"

COPY --from=rclone/rclone@sha256:d5971950c2b370fb04dd3292541b5bda6d9103143fd7e345aeb435a399388afc /usr/local/bin/rclone /usr/local/bin/rclone

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates fonts-wqy-microhei; \
    rm -rf /var/lib/apt/lists/*; \
    fc-cache -fv >/dev/null || true

ENTRYPOINT ["/bin/bash", "-lc"]
