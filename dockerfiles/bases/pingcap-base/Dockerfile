# hub.pingcap.net/bases/pingcap-base:v1.7.0
# hub.pingcap.net/bases/pingcap-base:v1.7
# hub.pingcap.net/bases/pingcap-base:v1
FROM rockylinux:9.2.20230513
RUN --mount=from=busybox:1.36.1,source=/bin,target=/busybox/bin \
	cp -a /busybox/bin/busybox /bin/busybox && \
	dnf upgrade -y python3 less && \
	dnf clean all
