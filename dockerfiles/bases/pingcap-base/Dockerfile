FROM quay.io/rockylinux/rockylinux:9.4.20240523
COPY --from=busybox:1.36.1 /bin/busybox /bin/busybox
RUN dnf upgrade -y python3 less && \
	dnf clean all
