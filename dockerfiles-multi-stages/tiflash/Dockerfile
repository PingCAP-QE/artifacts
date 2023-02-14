# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone https://github.com/pingcap/tiflash.git tiflash
#   - docker build -t tiflash -f Dockerfile ./tiflash

#build stag

FROM centos:7

COPY release-centos7-llvm/dockerfiles/misc /misc

RUN sh /misc/bake_llvm_base_amd64.sh

ENV PATH="/opt/cmake/bin:/usr/local/bin/:${PATH}:/usr/local/go/bin:/root/.cargo/bin" \
    LIBRARY_PATH="/usr/local/lib/x86_64-unknown-linux-gnu/:${LIBRARY_PATH}" \
    LD_LIBRARY_PATH="/usr/local/lib/x86_64-unknown-linux-gnu/:${LD_LIBRARY_PATH}" \
    CPLUS_INCLUDE_PATH="/usr/local/include/x86_64-unknown-linux-gnu/c++/v1/:${CPLUS_INCLUDE_PATH}" \
    OPENSSL_ROOT_DIR="/usr/local/opt/openssl" \
    CC=clang \
    CXX=clang++ \
    LD=ld.lld

ENV TZ Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /tiflash/
ADD . .
RUN "release-centos7-llvm/scripts/build-release.sh"
RUN /tiflash/bin/tiflash/tiflash  version

################

#final stage
FROM rockylinux:9
# pingcap-base
COPY --from=busybox:1.34.1 /bin/busybox /bin/busybox

ENV LD_LIBRARY_PATH /tiflash
COPY --from=builder /tiflash/bin/tiflash /tiflash

ENTRYPOINT ["/tiflash/tiflash", "server"]