msb-tikv: (_clone "tikv" "https://github.com/tikv/tikv.git" "master")
    docker build --load -t localhost/tikv:local-build -f dockerfiles/cd/builders/tikv/Dockerfile ../tikv

msb-tiflash: (_clone "tiflash" "https://github.com/pingcap/tiflash" "master")
    docker build --load -t localhost/tiflash:local-build -f dockerfiles/cd/builders/tiflash/Dockerfile ../tiflash

msb-dm: (_clone "tiflow" "https://github.com/pingcap/tiflow.git" "master")
    docker build --load -t localhost/dm:local-build -f dockerfiles/cd/builders/tiflow/Dockerfile --target final-dm ../tiflow

msb-cdc: (_clone "tiflow" "https://github.com/pingcap/tiflow.git" "master")
    docker build --load -t localhost/cdc:local-build -f dockerfiles/cd/builders/tiflow/Dockerfile --target final-cdc ../tiflow

msb-tidb: (_clone_without_submodules "tidb" "https://github.com/pingcap/tidb.git" "master")
    docker build --load -t localhost/tidb:local-build -f dockerfiles/cd/builders/tidb/Dockerfile ../tidb

msb-pd: (_clone "pd" "https://github.com/tikv/pd.git" "master")
    docker build --load -t localhost/pd:local-build -f dockerfiles/cd/builders/pd/Dockerfile ../pd

msb-ng-monitoring: (_clone "ng-monitoring" "https://github.com/pingcap/ng-monitoring.git" "main")
    docker build --load -t localhost/ng-monitoring:local-build -f dockerfiles/cd/builders/ng-monitoring/Dockerfile ../ng-monitoring

msb-tidb-dashboard: (_clone "tidb-dashboard" "https://github.com/pingcap/tidb-dashboard.git" "master")
    docker build --load -t localhost/tidb-dashboard:local-build -f dockerfiles/cd/builders/tidb-dashboard/Dockerfile ../tidb-dashboard

msb-tidb-operator: (_clone "tidb-operator" "https://github.com/pingcap/tidb-operator.git" "master")
    docker build --load -t localhost/tidb-operator:local-build -f dockerfiles/cd/builders/tidb-operator/Dockerfile ../tidb-operator

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
