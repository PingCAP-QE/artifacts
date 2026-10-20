FROM public.ecr.aws/amazonlinux/amazonlinux:2023.5.20240805.0@sha256:03c807fdc5d40ab06b21c2e6d158c63c37d5149a127b7fdfa9e3c1150352ff20
RUN yum install -y openssl && yum clean all
WORKDIR /qdrant-on-tidb
COPY serving-service qdrant-api ctl ./
# Refresh the certificate when the binaries change.
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
       -keyout key.pem -out cert.pem \
       -subj "/C=US/ST=Oregon/O=PingCAP/OU=TiDB Cloud/CN=qdrant-gateway.us-west-2.prod.aws.tidbcloud.com"
