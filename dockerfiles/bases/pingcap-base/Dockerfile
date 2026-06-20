FROM quay.io/rockylinux/rockylinux:9.7.20251123
COPY --from=busybox:1.37.0-musl /bin/busybox /bin/busybox
RUN _date=20260609 dnf upgrade -y && dnf clean all

# Add user and group to support run it with non-root.
ARG PINGCAP_UID=1000
ARG PINGCAP_GID=2000
RUN groupadd -g ${PINGCAP_GID} pingcap && \
    useradd -u ${PINGCAP_UID} -g ${PINGCAP_GID} -m pingcap

# Pre-install rclone and shush to avoid GitHub rate-limiting in CI.
ARG TARGETARCH
ARG RCLONE_VERSION=v1.71.2
ARG SHUSH_VERSION=v1.5.5
RUN dnf install -y unzip && dnf clean all && \
    curl -fsSL -o /tmp/rclone.zip https://github.com/ncw/rclone/releases/download/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-${TARGETARCH}.zip && \
    echo "$(case ${TARGETARCH} in \
        amd64) echo ab9fa5877cee91c64fdfd61a27028a458cf618b39259e5c371dc2ec34a12e415;; \
        arm64) echo e2e2efc7ed143026352d60216ef0d46d3fa4fe9d647eff1bd929e6fea498e6f1;; \
    esac) /tmp/rclone.zip" | sha256sum -c - && \
    unzip /tmp/rclone.zip -d /tmp && \
    mv /tmp/rclone-${RCLONE_VERSION}-linux-${TARGETARCH}/rclone /usr/local/bin/rclone && \
    chmod 755 /usr/local/bin/rclone && \
    rm -rf /tmp/rclone.zip /tmp/rclone-${RCLONE_VERSION}-linux-${TARGETARCH} && \
    curl -fsSL -o /usr/local/bin/shush https://github.com/realestate-com-au/shush/releases/download/${SHUSH_VERSION}/shush_linux_${TARGETARCH} && \
    echo "$(case ${TARGETARCH} in \
        amd64) echo d0e091405a18b6d11a65ea1d7449802c0cbac51971031897089d038e6f7cc750;; \
        arm64) echo 138af0f1eec3af50176d542fead8824c3ca0f6ba27a4a50e1db8af5959a13116;; \
    esac) /usr/local/bin/shush" | sha256sum -c - && \
    chmod 755 /usr/local/bin/shush
