msb-tikv: (_msb "tikv" "https://github.com/tikv/tikv.git")
msb-tiflash: (_msb "tiflash" "https://github.com/pingcap/tiflash")
msb-ticdc: (_msb "ticdc" "https://github.com/pingcap/tiflow.git")
##### follows are OK. ########
msb-tidb: (_msb "tidb" "https://github.com/pingcap/tidb.git")
msb-pd: (_msb "pd" "https://github.com/tikv/pd.git")

_msb component git_url:
    [ -e ../{{component}} ] || git clone {{git_url}} ../{{component}}
    ([ -e ../{{component}}/.dockerignore ] && rm ../{{component}}/.dockerignore) || true # make step depended on git metadata.
    docker build -t {{component}} -f dockerfiles-multi-stages/{{component}}/Dockerfile ../{{component}}
    docker run --rm {{component}} -V
