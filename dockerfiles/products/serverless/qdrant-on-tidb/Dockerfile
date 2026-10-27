FROM public.ecr.aws/amazonlinux/amazonlinux:2023.12.20261021.0@sha256:d9b4c61f49de68d41e43af1c0ef89c5600b0ad51da024406a15f5d014720c998
RUN yum install -y openssl && yum clean all
WORKDIR /qdrant-on-tidb
COPY serving-service qdrant-api ctl ./
# Refresh the certificate when the binaries change.
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
       -keyout key.pem -out cert.pem \
       -subj "/C=US/ST=Oregon/O=PingCAP/OU=TiDB Cloud/CN=qdrant-gateway.us-west-2.prod.aws.tidbcloud.com"
