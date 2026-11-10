FROM public.ecr.aws/amazonlinux/amazonlinux:2023.12.20261109.0@sha256:3f09d02367148ef8086b8dc7ce098d16b21da58bbfe1e1167da25a17df8f0e51
RUN yum install -y openssl && yum clean all
WORKDIR /qdrant-on-tidb
COPY serving-service qdrant-api ctl ./
# Refresh the certificate when the binaries change.
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
       -keyout key.pem -out cert.pem \
       -subj "/C=US/ST=Oregon/O=PingCAP/OU=TiDB Cloud/CN=qdrant-gateway.us-west-2.prod.aws.tidbcloud.com"
