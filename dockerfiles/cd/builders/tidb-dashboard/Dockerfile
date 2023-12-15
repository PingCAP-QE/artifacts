FROM centos:7.9.2009 as builder

RUN yum -y update
RUN yum -y groupinstall "Development Tools"

# Install golang.
ENV PATH /usr/local/go/bin:$PATH
RUN export ARCH=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && \\
    export GO_VERSION=1.19.5 && \\
    curl -OL https://golang.org/dl/go$GO_VERSION.linux-$ARCH.tar.gz && \\
    tar -C /usr/local/ -xzf go$GO_VERSION.linux-$ARCH.tar.gz && \\
    rm -f go$GO_VERSION.linux-$ARCH.tar.gz
ENV GOROOT /usr/local/go
ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# Install nodejs.
RUN curl -fsSL https://rpm.nodesource.com/setup_16.x | bash -
RUN yum -y install nodejs
RUN npm install -g pnpm@7.30.5

# Install java.
RUN yum -y install java-11-openjdk

RUN mkdir -p /go/src/github.com/pingcap/tidb-dashboard/ui
WORKDIR /go/src/github.com/pingcap/tidb-dashboard
