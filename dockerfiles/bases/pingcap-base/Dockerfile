FROM quay.io/rockylinux/rockylinux:9.5.20241118
COPY --from=busybox:1.37.0 /bin/busybox /bin/busybox
RUN _date=20240730 dnf upgrade -y && dnf clean all

# Add user and group to support run it with non-root.
ARG PINGCAP_UID=1000
ARG PINGCAP_GID=2000
RUN groupadd -g ${PINGCAP_GID} pingcap && \
    useradd -u ${PINGCAP_UID} -g ${PINGCAP_GID} -m pingcap
