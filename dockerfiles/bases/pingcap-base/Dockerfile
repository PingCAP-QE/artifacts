# hub.pingcap.net/bases/pingcap-base:v1.4.0
# hub.pingcap.net/bases/pingcap-base:v1.4
# hub.pingcap.net/bases/pingcap-base:v1
FROM rockylinux:9.1.20230215
RUN --mount=from=busybox:1.36.0,source=/bin,target=/busybox/bin \
	cp -a /busybox/bin/busybox /bin/busybox
