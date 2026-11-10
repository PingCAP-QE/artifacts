FROM public.ecr.aws/amazonlinux/amazonlinux:2023.12.20261102.0@sha256:381352c430f36d8aa6b8b670de06e7e4e5642fe0cb9dbd463bb8d1e79aefc0c7
RUN yum install -y openssl && yum clean all
WORKDIR /qdrant-on-tidb
COPY serving-service qdrant-api ctl ./
