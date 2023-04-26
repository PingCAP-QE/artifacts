# hub.pingcap.net/bases/pingcap-base:v1.5.0
# hub.pingcap.net/bases/pingcap-base:v1.5
# hub.pingcap.net/bases/pingcap-base:v1
FROM rockylinux:9.1.20230215
RUN --mount=from=busybox:1.36.0,source=/bin,target=/busybox/bin \
	cp -a /busybox/bin/busybox /bin/busybox && \
	dnf upgrade -y openssl lua-libs tar systemd-libs python3 python3-setuptools-wheel vim-minimal && \
	dnf clean all
