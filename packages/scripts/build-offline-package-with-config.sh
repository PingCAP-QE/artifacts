#!/usr/bin/env bash
set -euxo pipefail

RELEASE_SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT_DIR=$(realpath "${RELEASE_SCRIPTS_DIR}/../..")

function config_driven() {
    local os=$1
    local arch=$2
    local version=$3
    local release_ws=$4
    local edition="${5:-community}"

    # prepare template file's context.
    : >release-context.yaml
    yq -i ".Release.os=\"$os\"" release-context.yaml
    yq -i ".Release.arch=\"$arch\"" release-context.yaml
    yq -i ".Release.version=\"$version\"" release-context.yaml

    gomplate --context .=release-context.yaml -f "$PROJECT_ROOT_DIR/config/release/offline-packages.yaml.tmpl" --out release-offline-packages.yaml

    # filter by os and arch and release version.
    yq ".artifacts.${edition}.routers | map(select(
            .if
            and ([\"$os\"] - .os | length == 0)
            and ([\"$arch\"] - .arch | length == 0)
        ))" release-offline-packages.yaml >release-offline-packages-routes.yaml

    # fail when array length greater than 1.
    if yq -e 'length > 1' release-offline-packages-routes.yaml >/dev/null 2>&1; then
        echo "Error: wrong offline package config that make me matched more than 1 routes!"
        exit 1
    fi

    if yq -e 'length == 0' release-offline-packages-routes.yaml >/dev/null 2>&1; then
        echo "No package routes matched for arch: $arch, version: $version ."
        exit 0
    fi

    release_ws=$(realpath $release_ws)
    # walk for artifact config
    for i in $(seq 0 $(yq '.0.artifacts | length - 1' release-offline-packages-routes.yaml)); do
        yq ".[0].artifacts[$i]" release-offline-packages-routes.yaml >release-offline-packages-artifact-$i.yaml
        yq -i ".arch=\"$arch\"" release-offline-packages-artifact-$i.yaml
        yq -i ".os=\"$os\"" release-offline-packages-artifact-$i.yaml

        # generate package script
        local release_scripts_dir="$PROJECT_ROOT_DIR/scripts/pingcap/release"
        gomplate --context .=release-offline-packages-artifact-$i.yaml -f $release_scripts_dir/compose-offline-packages-artifact.sh.tmpl --chmod "755" --out $release_scripts_dir/compose-offline-packages-artifact.sh

        # run it.
        pushd "$(mktemp -d -p $release_ws)"
        $release_scripts_dir/compose-offline-packages-artifact.sh $os $arch $version $release_ws
        popd
    done
}

function install_tiup_tool() {
    local run_os="$(uname -s)"
    local run_arch="$(uname -m)"
    local tiup_ver="v1.12.5"
    local tiup_tarball

    case "${run_os}/${run_arch}" in
    Linux/aarch64)
        tiup_tarball="https://tiup-mirrors.pingcap.com/tiup-${tiup_ver}-linux-arm64.tar.gz"
        ;;
    Linux/x86_64)
        tiup_tarball="https://tiup-mirrors.pingcap.com/tiup-${tiup_ver}-linux-amd64.tar.gz"
        ;;
    Darwin/arm64)
        tiup_tarball="https://tiup-mirrors.pingcap.com/tiup-${tiup_ver}-darwin-arm64.tar.gz"
        ;;
    Darwin/x86_64)
        tiup_tarball="https://tiup-mirrors.pingcap.com/tiup-${tiup_ver}-darwin-amd64.tar.gz"
        ;;
    *)
        echo "Unsupported platform: ${run_os}/${run_arch}"
        exit 1
        ;;
    esac

    # install tiup
    wget -O - "$tiup_tarball" | tar -C /usr/local/bin -zxv tiup
    mkdir -p ~/.tiup/bin/
}

function main() {
    install_tiup_tool
    config_driven "$@"
}

main "$@"
