msb-tikv: (_msb "tikv" "https://github.com/tikv/tikv.git" "master")
    docker run --rm tikv:latest --version

msb-tiflash: (_msb "tiflash" "https://github.com/pingcap/tiflash" "master")
    docker run --rm --entrypoint=/tiflash/tiflash tiflash:latest version

msb-dm: (_msb "dm" "https://github.com/pingcap/tiflow.git" "master")
    docker run --rm dm /dm-master -V
    docker run --rm dm /dm-worker -V
    docker run --rm dm /dm-syncer -V
    docker run --rm dm /dmctl -V

msb-ticdc: (_msb "ticdc" "https://github.com/pingcap/tiflow.git" "master")
    docker run --rm ticdc /cdc version

msb-tidb: (_msb "tidb" "https://github.com/pingcap/tidb.git" "master")
    docker run --rm tidb -V

msb-pd: (_msb "pd" "https://github.com/tikv/pd.git" "master")
    docker run --rm pd -V

build_product_base_images: (_docker_build_prod_base_images "hub.pingcap.net/bases")

_msb component git_url git_branch:
    [ -e ../{{component}} ] || git clone --recurse-submodules {{git_url}} --branch {{git_branch}} ../{{component}}
    ([ -e ../{{component}}/.dockerignore ] && rm ../{{component}}/.dockerignore) || true # make step depended on git metadata.
    docker build -t {{component}} -f dockerfiles-multi-stages/{{component}}/Dockerfile ../{{component}}

_docker_build_prod_base_images registry_prefix:
    cd dockerfiles/build_product_base_images
    skaffold build --profile local-docker --default-repo {{registry_prefix}}
