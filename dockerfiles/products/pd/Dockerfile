# ---- Base stage: shared for both root and non-root images ----
ARG BASE_IMG=ghcr.io/pingcap-qe/bases/pd-base:v1.9.2
FROM $BASE_IMG as base
COPY pd-server /pd-server
COPY pd-ctl /pd-ctl
COPY pd-recover /pd-recover
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]

# ---- Non-root image stage ----
FROM base as nonroot
RUN groupadd -g 2000 pingcap && \
    useradd -u 1000 -g 2000 -m pingcap
USER pingcap:pingcap

# ---- Root image stage (default) ----
FROM base as root
