FROM quay.io/rockylinux/rockylinux:9.8.20260525.0
COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox

ARG _date=20260714
ARG PINGCAP_UID=1000
ARG PINGCAP_GID=2000
RUN dnf upgrade -y && dnf clean all && \
    groupadd -g ${PINGCAP_GID} pingcap && \
    useradd -u ${PINGCAP_UID} -g ${PINGCAP_GID} -m pingcap
