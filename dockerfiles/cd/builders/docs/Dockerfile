# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - docker build --platform=linux/amd64 --target builder -t docs-builder -f dockerfiles/cd/builders/docs/Dockerfile .
#   - docker build --platform=linux/amd64 --target test -t docs-builder-test -f dockerfiles/cd/builders/docs/Dockerfile .

########### stage: docs-base
FROM python:3.10-slim-bookworm AS docs-base

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    RCLONE_VERSION=v1.69.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      fontconfig \
      git \
      locales \
      texlive-xetex \
      texlive-latex-extra \
      texlive-lang-cjk \
      fonts-wqy-microhei \
 && curl -fsSL -o /tmp/pandoc.deb \
      "https://github.com/jgm/pandoc/releases/download/1.19.2/pandoc-1.19.2-1-amd64.deb" \
 && apt-get install -y --no-install-recommends /tmp/pandoc.deb \
 && pandoc --version | head -n 1 \
 && rm -f /tmp/pandoc.deb \
 && rm -rf /var/lib/apt/lists/* \
 && ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime \
 && (locale-gen C.UTF-8 || true)

########### stage: test
FROM docs-base AS test
ARG DOCS_REPO=https://github.com/pingcap/docs.git
WORKDIR /work
RUN git clone --depth=1 "${DOCS_REPO}" docs
WORKDIR /work/docs
RUN python3 scripts/merge_by_toc.py \
 && bash scripts/generate_pdf.sh \
 && test -s doc.md \
 && test -s output.pdf

########### stage: builder
FROM docs-base AS builder
LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description="builder for PingCAP docs PDF generation"
LABEL org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      jq \
      openssh-client \
      unzip \
 && rm -rf /var/lib/apt/lists/*

RUN python -m pip install \
      boto3==1.23.10 \
      awscli==1.24.10

RUN curl -fsSL -o /tmp/rclone.zip \
      "https://downloads.rclone.org/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-amd64.zip" \
 && unzip -q /tmp/rclone.zip -d /tmp \
 && install -m 0755 \
      "/tmp/rclone-${RCLONE_VERSION}-linux-amd64/rclone" \
      /usr/local/bin/rclone \
 && rm -rf /tmp/rclone.zip "/tmp/rclone-${RCLONE_VERSION}-linux-amd64"

WORKDIR /work
CMD ["/bin/sh"]

########### stage: final
FROM builder AS final
