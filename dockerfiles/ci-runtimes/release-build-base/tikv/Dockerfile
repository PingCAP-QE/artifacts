FROM rockylinux:8.8.20230518
RUN yum groupinstall -y "Development Tools"
RUN yum --enablerepo=powertools install -y git make cmake gawk llvm protobuf-compiler libstdc++-static python3 && yum clean all
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain none
RUN ln -s /usr/bin/python3 /usr/bin/python
ENV PATH /root/.cargo/bin/:$PATH
