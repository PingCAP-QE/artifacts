# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - docker build --platform=linux/amd64 --target builder -t docs-builder -f dockerfiles/cd/builders/docs/Dockerfile .
#   - docker build --platform=linux/amd64 --target test -t docs-builder-test -f dockerfiles/cd/builders/docs/Dockerfile .

########### stage: builder
FROM python:3.6.15 AS builder
LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description="builder for PingCAP docs PDF generation"
LABEL org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Fix EOL of the bullseye sources
RUN printf '%s\n' \
      'deb http://deb.debian.org/debian bullseye main' \
      'deb http://deb.debian.org/debian-security bullseye-security main' \
      'deb http://deb.debian.org/debian bullseye-updates main' \
      >/etc/apt/sources.list \
 && printf '%s\n' \
      'Acquire::Check-Valid-Until "false";' \
      >/etc/apt/apt.conf.d/99archive

# Install tools for generating the PDF documents.
ARG PANDOC_VERSION=1.19.2
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      locales \
      lmodern \
      openssh-client \
      texlive-fonts-recommended \
      texlive-lang-chinese \
      texlive-xetex \
      texlive-latex-extra \
      texlive-lang-cjk \
      fonts-wqy-microhei \
      unzip \
 && ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime \
 && (locale-gen C.UTF-8 || true) \
 && curl -fsSL -o /tmp/pandoc.deb \
      "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb" \
 && dpkg -i /tmp/pandoc.deb \
 && pandoc --version | head -n 1 \
 && rm -f /tmp/pandoc.deb \
 && rm -rf /var/lib/apt/lists/*

COPY pandoc-horizontal-rule-filter.py /usr/local/bin/pandoc-horizontal-rule-filter
COPY pandoc-wrapper.sh /usr/local/bin/pandoc
RUN chmod 0755 \
      /usr/local/bin/pandoc \
      /usr/local/bin/pandoc-horizontal-rule-filter

ARG BOTO3_VERSION=1.23.10
ARG AWSCLI_VERSION=1.24.10
RUN pip --trusted-host pypi.org \
        --trusted-host pypi.python.org \
        --trusted-host files.pythonhosted.org \
        install \
          boto3==${BOTO3_VERSION} \
          awscli==${AWSCLI_VERSION}

ARG RCLONE_VERSION=v1.69.0
RUN curl -fsSL -o /tmp/rclone.zip \
      "https://downloads.rclone.org/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-amd64.zip" \
 && unzip -q /tmp/rclone.zip -d /tmp \
 && install -m 0755 \
      "/tmp/rclone-${RCLONE_VERSION}-linux-amd64/rclone" \
      /usr/local/bin/rclone \
 && rm -rf /tmp/rclone.zip "/tmp/rclone-${RCLONE_VERSION}-linux-amd64"

ENTRYPOINT ["/bin/bash"]

########### stage: test
FROM builder AS test
ARG DOCS_REPO=https://github.com/pingcap/docs.git
WORKDIR /work
RUN git clone --depth=1 "${DOCS_REPO}" docs
WORKDIR /work/docs
RUN python3 scripts/merge_by_toc.py \
 && bash scripts/generate_pdf.sh \
 && ls -lh doc.md output.pdf \
 && test -s doc.md \
 && test -s output.pdf

########### stage: final
FROM builder AS final
