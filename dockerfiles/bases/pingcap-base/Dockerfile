# hub.pingcap.net/bases/pingcap-base:v1.6.0
# hub.pingcap.net/bases/pingcap-base:v1.6
# hub.pingcap.net/bases/pingcap-base:v1
FROM rockylinux:9.2.20230513
RUN --mount=from=busybox:1.36.0,source=/bin,target=/busybox/bin \
	cp -a /busybox/bin/busybox /bin/busybox && \
	dnf clean all
