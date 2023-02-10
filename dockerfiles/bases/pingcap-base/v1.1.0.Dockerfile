# hub.pingcap.net/bases/pingcap-base
FROM rockylinux:9.0.20220720
COPY --from=busybox:1.34.1 /bin/busybox /bin/busybox
