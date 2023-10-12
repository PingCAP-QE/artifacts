# hub.pingcap.net/bases/pingcap-base:v1.7.0
# hub.pingcap.net/bases/pingcap-base:v1.7
# hub.pingcap.net/bases/pingcap-base:v1
FROM rockylinux:9.2.20230513
COPY --from=busybox:1.36.1 /bin/busybox /bin/busybox
RUN	dnf upgrade -y python3 less && \
	dnf clean all
