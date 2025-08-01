FROM quay.io/rockylinux/rockylinux:9.6.20250531
COPY --from=busybox:1.37.0 /bin/busybox /bin/busybox
RUN _date=20240730 dnf upgrade -y && dnf clean all
