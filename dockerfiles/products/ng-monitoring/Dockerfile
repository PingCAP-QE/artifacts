ARG BASE_IMG=ghcr.io/pingcap-qe/bases/ng-monitoring-base:v1.9.2

# ---- Base stage: shared for both root and non-root images ----
FROM $BASE_IMG as base
COPY ng-monitoring-server /ng-monitoring-server
EXPOSE 12020
ENTRYPOINT ["/ng-monitoring-server"]

# ---- Non-root image stage ----
FROM base as nonroot
RUN groupadd -g 2000 pingcap && \
    useradd -u 1000 -g 2000 -m pingcap
USER pingcap:pingcap

# ---- Root image stage (default) ----
FROM base as root
