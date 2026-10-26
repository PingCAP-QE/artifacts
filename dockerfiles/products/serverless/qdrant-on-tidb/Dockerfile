FROM public.ecr.aws/amazonlinux/amazonlinux:2023.12.20261026.1@sha256:8272aee6146a36222baaf71d72ab6799770957414ac63b1e940cec58c9197188
RUN yum install -y openssl && yum clean all
WORKDIR /qdrant-on-tidb
COPY serving-service qdrant-api ctl ./
# Refresh the certificate when the binaries change.
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
       -keyout key.pem -out cert.pem \
       -subj "/C=US/ST=Oregon/O=PingCAP/OU=TiDB Cloud/CN=qdrant-gateway.us-west-2.prod.aws.tidbcloud.com"
