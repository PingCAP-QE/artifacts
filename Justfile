msb-tikv: (_msb "tikv" "https://github.com/tikv/tikv.git")
msb-tiflash: (_msb "tiflash" "https://github.com/pingcap/tiflash")

##### follows are OK. ########
msb-ticdc: (_msb "ticdc" "https://github.com/pingcap/tiflow.git")
    docker run --rm ticdc /cdc version

msb-tidb: (_msb "tidb" "https://github.com/pingcap/tidb.git")
    docker run --rm tidb -V

msb-pd: (_msb "pd" "https://github.com/tikv/pd.git")
    docker run --rm pd -V

_msb component git_url:
    [ -e ../{{component}} ] || git clone {{git_url}} ../{{component}}
    ([ -e ../{{component}}/.dockerignore ] && rm ../{{component}}/.dockerignore) || true # make step depended on git metadata.
    docker build -t {{component}} -f dockerfiles-multi-stages/{{component}}/Dockerfile ../{{component}}
