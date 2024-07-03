# Ref: https://github.com/sqawasmi/trafficserver-docker/blob/master/Dockerfile
FROM debian:12.6

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.source = "https://github.com/PingCAP-QE/artifacts"

# renovate: datasource=github-tags depName=apache/trafficserver
ARG TRAFFIC_SERVER_VERSION=9.2.4

# Update the package repository
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y curl locales build-essential bzip2 libssl-dev libxml2-dev libpcre3-dev tcl-dev libboost-dev \
    && rm -rf /var/lib/apt/lists/* \
    && export LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/environment && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && locale-gen en_US.UTF-8 \
    && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
    && mkdir -p /tmp/trafficserver \
    && curl -L https://downloads.apache.org/trafficserver/trafficserver-${TRAFFIC_SERVER_VERSION}.tar.bz2 | tar xjvf - -C /tmp/trafficserver --strip-components 1 \
    && cd /tmp/trafficserver && ./configure --prefix=/opt/trafficserver \
    && cd /tmp/trafficserver && make \
    && cd /tmp/trafficserver && make install \
    && mv /opt/trafficserver/etc/trafficserver /etc/trafficserver \
    && ln -sf /etc/trafficserver /opt/trafficserver/etc/trafficserver \
    && rm -rf /tmp/trafficserver

EXPOSE 8080
CMD ["/opt/trafficserver/bin/traffic_server"]
