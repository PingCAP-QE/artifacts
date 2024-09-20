FROM quay.io/rockylinux/rockylinux:9.4.20240523
COPY --from=busybox:1.36.1 /bin/busybox /bin/busybox
RUN _date=20240920 dnf upgrade -y && dnf clean all && rm -rf /var/cache/yum
