# base image dockerfile: cd/builders/tiflash/Dockerfile
ARG BASE_IMG
FROM $BASE_IMG

# create user jenkins and add it to sudoers.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y sudo
RUN groupadd -g 1000 jenkins && \
    useradd -u 1000 -g 1000 -m -s /bin/bash jenkins && \
    echo "jenkins:password" | chpasswd && \
    echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# install ccache
RUN wget https://github.com/ccache/ccache/releases/download/v4.5.1/ccache-4.5.1.tar.gz && \
    tar -xzf ccache-4.5.1.tar.gz && \
    mkdir -p ccache-4.5.1/build && \
    cd ccache-4.5.1/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release \
      -DZSTD_FROM_INTERNET=ON \
      -DHIREDIS_FROM_INTERNET=ON \
      -DENABLE_TESTING=OFF \
      -DCMAKE_INSTALL_PREFIX="/usr/local" \
      -GNinja && \
    ninja && \
    ninja install && \
    mkdir -p /usr/lib64/ccache && \
    ln -s `which ccache` /usr/lib64/ccache/clang && \
    ln -s `which ccache` /usr/lib64/ccache/clang++ && \
    cd ../.. && \
    rm -rf ccache-4.5.1 && \
    rm ccache-4.5.1.tar.gz

# Switch to the non-root user jenkins and set the working directory
USER jenkins
WORKDIR /home/jenkins
