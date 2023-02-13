


FROM hub.pingcap.net/tiflash/centos:7.9.2009-amd64

COPY misc /misc

RUN sh /misc/bake_llvm_base_amd64.sh

ENV PATH="/opt/cmake/bin:/usr/local/bin/:${PATH}:/usr/local/go/bin:/root/.cargo/bin" \
    LIBRARY_PATH="/usr/local/lib/x86_64-unknown-linux-gnu/:${LIBRARY_PATH}" \
    LD_LIBRARY_PATH="/usr/local/lib/x86_64-unknown-linux-gnu/:${LD_LIBRARY_PATH}" \
    CPLUS_INCLUDE_PATH="/usr/local/include/x86_64-unknown-linux-gnu/c++/v1/:${CPLUS_INCLUDE_PATH}" \
    OPENSSL_ROOT_DIR="/usr/local/opt/openssl" \
    CC=clang \
    CXX=clang++ \
    LD=ld.lld

USER root
WORKDIR /root/
ENV HOME /root/
ENV TZ Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN """
if [ ${RELEASE_TAG}x != ''x ];then
    for a in \$(git tag --contains ${GIT_HASH}); do echo \$a && git tag -d \$a;done
    git tag -f ${RELEASE_TAG} ${GIT_HASH}
    git branch -D refs/tags/${RELEASE_TAG} || true
    git checkout -b refs/tags/${RELEASE_TAG}
fi;
if [ ${EDITION} == 'enterprise' ]; then
    export TIFLASH_EDITION=Enterprise
fi;
if [ ${OS} == 'darwin' ]; then
    if [ ${ARCH} == "arm64" ]; then
        cd ..
        cp -f /Users/pingcap/birdstorm/fix-poco.sh ./
        cp -f /Users/pingcap/birdstorm/fix-libdaemon.sh ./
        ./fix-poco.sh
        ./fix-libdaemon.sh
        cd tics
    fi
    export PROTOC=/usr/local/bin/protoc
    export PATH=/usr/local/opt/binutils/bin:/usr/local/bin:/Users/pingcap/.cargo/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${GO_BIN_PATH}
    mkdir -p release-darwin/build/
    [ -f "release-darwin/build/build-release.sh" ] || curl -s ${FILE_SERVER_URL}/download/builds/pingcap/ee/tiflash/build-release.sh > release-darwin/build/build-release.sh
    [ -f "release-darwin/build/build-cluster-manager.sh" ] || curl -s ${FILE_SERVER_URL}/download/builds/pingcap/ee/tiflash/build-cluster-manager.sh > release-darwin/build/build-cluster-manager.sh
    [ -f "release-darwin/build/build-tiflash-proxy.sh" ] || curl -s ${FILE_SERVER_URL}/download/builds/pingcap/ee/tiflash/build-tiflash-proxy.sh > release-darwin/build/build-tiflash-proxy.sh
    [ -f "release-darwin/build/build-tiflash-release.sh" ] || curl -s ${FILE_SERVER_URL}/download/builds/pingcap/ee/tiflash/build-tiflash-release.sh > release-darwin/build/build-tiflash-release.sh
    chmod +x release-darwin/build/*
    ./release-darwin/build/build-release.sh
    ls -l ./release-darwin/tiflash/
    mv release-darwin ${TARGET}
else
    if [ "${params.USE_TIFLASH_RUST_CACHE}" == "true" ]; then
        mkdir -p ~/.cargo/registry
        mkdir -p ~/.cargo/git
        mkdir -p /rust/registry/cache
        mkdir -p /rust/registry/index 
        mkdir -p /rust/git/db
        mkdir -p /rust/git/checkouts
        
        rm -rf ~/.cargo/registry/cache && ln -s /rust/registry/cache ~/.cargo/registry/cache
        rm -rf ~/.cargo/registry/index && ln -s /rust/registry/index ~/.cargo/registry/index 
        rm -rf ~/.cargo/git/db && ln -s /rust/git/db ~/.cargo/git/db
        rm -rf ~/.cargo/git/checkouts && ln -s /rust/git/checkouts ~/.cargo/git/checkouts
    fi

    # check if LLVM toolchain is provided
    echo "the new parameter of tiflash debug is : ${params.TIFLASH_DEBUG}"
    
    if [[ -d "release-centos7-llvm" && \$(which clang 2>/dev/null) ]]; then
        if [[ "${params.TIFLASH_DEBUG}" != 'true' ]]; then
            echo "start release ..........."
            NPROC=12 release-centos7-llvm/scripts/build-release.sh
        else
            echo "start debug ..........."
            NPROC=12 release-centos7-llvm/scripts/build-debug.sh
        fi
        mkdir -p ${TARGET}
        mv release-centos7-llvm/tiflash ${TARGET}/tiflash
    else
        if [[ "${params.TIFLASH_DEBUG}" != 'true' ]]; then
            echo "start release ..........."
            NPROC=12 release-centos7/build/build-release.sh
        else
            echo "start debug ..........."
            NPROC=12 release-centos7/build/build-debug.sh
        fi
        mkdir -p ${TARGET}
        mv release-centos7/tiflash ${TARGET}/tiflash
    fi
fi
rm -rf ${TARGET}/build-release || true
"""

FROM hub.pingcap.net/bases/pingcap-base:v1.1.0
ENV LD_LIBRARY_PATH /tiflash
COPY tiflash /tiflash
ENTRYPOINT ["/tiflash/tiflash", "server"]
