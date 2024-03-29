msb-tikv: (_clone "tikv" "https://github.com/tikv/tikv.git" "master")
    docker build --load -t localhost/tikv:local-build -f dockerfiles/cd/builders/tikv/Dockerfile ../tikv
    docker run --rm localhost/tikv:local-build --version

msb-tiflash: (_clone "tiflash" "https://github.com/pingcap/tiflash" "master")
    docker build --load -t localhost/tiflash:local-build -f dockerfiles/cd/builders/tiflash/Dockerfile ../tiflash
    docker run --rm --entrypoint=/tiflash/tiflash localhost/tiflash:local-build version

msb-dm: (_clone "tiflow" "https://github.com/pingcap/tiflow.git" "master")
    docker build --load -t localhost/dm:local-build -f dockerfiles/cd/builders/tiflow/Dockerfile --target final-dm ../tiflow
    docker run --rm localhost/dm:local-build /dm-master -V
    docker run --rm localhost/dm:local-build /dm-worker -V
    docker run --rm localhost/dm:local-build /dm-syncer -V
    docker run --rm localhost/dm:local-build /dmctl -V

msb-ticdc: (_clone "tiflow" "https://github.com/pingcap/tiflow.git" "master")
    docker build --load -t localhost/ticdc:local-build -f dockerfiles/cd/builders/tiflow/Dockerfile --target final-cdc ../tiflow
    docker run --rm localhost/ticdc:local-build /cdc version

msb-tidb: (_clone_without_submodules "tidb" "https://github.com/pingcap/tidb.git" "master")
    docker build --load -t localhost/tidb:local-build -f dockerfiles/cd/builders/tidb/Dockerfile ../tidb
    docker run --rm localhost/tidb:local-build -V

msb-pd: (_clone "pd" "https://github.com/tikv/pd.git" "master")
    docker build --load -t localhost/pd:local-build -f dockerfiles/cd/builders/pd/Dockerfile ../pd
    docker run --rm localhost/pd:local-build -V

build_product_base_images: (_docker_build_prod_base_images "hub.pingcap.net/bases")

_msb component git_url git_branch:
    [ -e ../{{component}} ] || git clone --recurse-submodules {{git_url}} --branch {{git_branch}} ../{{component}}
    ([ -e ../{{component}}/.dockerignore ] && rm ../{{component}}/.dockerignore) || true # make step depended on git metadata.
    docker build -t {{component}} -f dockerfiles-multi-stages/{{component}}/Dockerfile ../{{component}}

_clone component git_url git_branch:
    [ -e ../{{component}} ] || git clone --recurse-submodules {{git_url}} --branch {{git_branch}} ../{{component}}
    ([ -e ../{{component}}/.dockerignore ] && rm ../{{component}}/.dockerignore) || true # make step depended on git metadata.

_clone_without_submodules component git_url git_branch:
    [ -e ../{{component}} ] || git clone {{git_url}} --branch {{git_branch}} ../{{component}}
    ([ -e ../{{component}}/.dockerignore ] && rm ../{{component}}/.dockerignore) || true # make step depended on git metadata.

_docker_build_prod_base_images registry_prefix:
    cd dockerfiles/bases; skaffold build --profile local-docker --default-repo {{registry_prefix}}
