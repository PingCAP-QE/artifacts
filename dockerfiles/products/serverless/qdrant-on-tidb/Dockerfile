FROM public.ecr.aws/amazonlinux/amazonlinux:2023.12.20261127.0@sha256:47a249649c57ca32b2d4bd5f46149383d5852610eb2c6230e33ce9c3ab8c8459
RUN yum install -y openssl && yum clean all
WORKDIR /qdrant-on-tidb
COPY serving-service qdrant-api ctl ./
