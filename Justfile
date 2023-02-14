msb-tikv: (_msb "tikv" "https://github.com/tikv/tikv.git")
    docker run --rm tikv:latest --version

msb-tiflash: (_msb "tiflash" "https://github.com/pingcap/tiflash")
    docker run --rm --entrypoint=/tiflash/tiflash tiflash:latest version

msb-dm: (_msb "dm" "https://github.com/pingcap/tiflow.git")
    docker run --rm dm /dm-master -V
    docker run --rm dm /dm-worker -V
    docker run --rm dm /dm-syncer -V
    docker run --rm dm /dmctl -V

msb-ticdc: (_msb "ticdc" "https://github.com/pingcap/tiflow.git")
    docker run --rm ticdc /cdc version

msb-tidb: (_msb "tidb" "https://github.com/pingcap/tidb.git")
    docker run --rm tidb -V

msb-pd: (_msb "pd" "https://github.com/tikv/pd.git")
    docker run --rm pd -V

_msb component git_url:
    [ -e ../{{component}} ] || git clone --recurse-submodules {{git_url}} ../{{component}}
    ([ -e ../{{component}}/.dockerignore ] && rm ../{{component}}/.dockerignore) || true # make step depended on git metadata.
    docker build -t {{component}} -f dockerfiles-multi-stages/{{component}}/Dockerfile ../{{component}}
