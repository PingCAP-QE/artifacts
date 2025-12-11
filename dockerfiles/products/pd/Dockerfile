# syntax=docker/dockerfile:1
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pd-base:v1.11.0
FROM $BASE_IMG
COPY --chmod=755 pd-server pd-ctl pd-recover /
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
