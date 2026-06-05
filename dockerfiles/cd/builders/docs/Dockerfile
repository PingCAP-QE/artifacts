# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - docker build --platform=linux/amd64 --target builder -t docs-builder -f dockerfiles/cd/builders/docs/Dockerfile .
#   - docker build --platform=linux/amd64 --target test -t docs-builder-test -f dockerfiles/cd/builders/docs/Dockerfile .

########### stage: builder
FROM --platform=linux/amd64 python:3.10-slim-bookworm AS builder
LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description="builder for PingCAP docs PDF generation"
LABEL org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts"

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
      jq \
      locales \
      openssh-client \
      unzip \
      xvfb \
      pandoc \
      texlive-xetex \
      texlive-fonts-recommended \
      texlive-latex-extra \
      texlive-lang-chinese \
      fonts-wqy-microhei \
      fonts-wqy-zenhei \
 && rm -rf /var/lib/apt/lists/* \
 && ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime \
 && locale-gen C.UTF-8 || true

RUN python -m pip install --upgrade pip setuptools wheel \
 && python -m pip install \
      qiniu \
      boto3 \
      awscli

RUN curl -fsSL -o /tmp/rclone.zip \
      "https://downloads.rclone.org/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-amd64.zip" \
 && unzip -q /tmp/rclone.zip -d /tmp \
 && install -m 0755 \
      "/tmp/rclone-${RCLONE_VERSION}-linux-amd64/rclone" \
      /usr/local/bin/rclone \
 && rm -rf /tmp/rclone.zip "/tmp/rclone-${RCLONE_VERSION}-linux-amd64"

WORKDIR /work
CMD ["/bin/sh"]

########### stage: test
FROM builder AS test
ARG DOCS_REPO=https://github.com/pingcap/docs.git
WORKDIR /work
RUN git clone --depth=1 "${DOCS_REPO}" docs
WORKDIR /work/docs
RUN python3 scripts/merge_by_toc.py \
 && bash scripts/generate_pdf.sh \
 && test -s doc.md \
 && test -s output.pdf

########### stage: final
FROM builder AS final
