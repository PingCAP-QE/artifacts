#!/usr/bin/env bash
set -euo pipefail

RELEASE_SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT_DIR=$(realpath "${RELEASE_SCRIPTS_DIR}/../..")

function main() {
    local os=$1
    local arch=$2
    local version=$3
    local edition="${4:-community}"
    local template_file="${5:-${PROJECT_ROOT_DIR}/packages/offline-packages.yaml.tmpl}"
    local out_file="${6:-${RELEASE_SCRIPTS_DIR}/compose-offline-packages-artifacts.sh}"
    local tiup_mirror="${7:---reset}"
    local registry="${8:-hub.pingcap.net}"

    local target_info="os: $os, arch: $arch, version: $version, edition: $edition"

    # prepare template file's context.
    : >release-context.yaml
    yq -i ".Release.os = \"$os\"" release-context.yaml
    yq -i ".Release.arch = \"$arch\"" release-context.yaml
    yq -i ".Release.version = \"$version\"" release-context.yaml
    yq -i ".Release.edition = \"$edition\"" release-context.yaml
    yq -i ".Release.registry = \"$registry\"" release-context.yaml
    gomplate --context .=release-context.yaml -f "$template_file" --out release-packages.yaml
    yq ".editions[\"${edition}\"]" release-packages.yaml >release-package.yaml

    # filter routers by os and arch and release version.
    yq -i ".routers |= map(select(
            (.if != false)
            and ([\"$os\"] - .os | length == 0)
            and ([\"$arch\"] - .arch | length == 0)
        ))" release-package.yaml
    yq -i '.routers[].artifactory = .artifactory' release-package.yaml

    # fail when array length greater than 1.
    if yq -e '.routers | length > 1' release-package.yaml >/dev/null 2>&1; then
        echo "Error: wrong package config that make me matched more than 1 routes!"
        exit 1
    fi
    if yq -e '.routers | length == 0' release-package.yaml >/dev/null 2>&1; then
        echo "No package routes matched for the target($target_info)." >&2
        exit 1
    fi
    yq ".routers[0]" release-package.yaml >release-router.yaml

    # generate package build script
    yq -i ".os = \"$os\"" release-router.yaml
    yq -i ".arch = \"$arch\"" release-router.yaml
    yq -i ".version = \"$version\"" release-router.yaml
    yq -i ".edition = \"$edition\"" release-router.yaml
    yq -i ".tiup_mirror = \"$tiup_mirror\"" release-router.yaml

    yq -i '.artifacts |= map(select(.if == null or .if))' release-router.yaml
    if yq -e '.artifacts | length == 0' release-router.yaml >/dev/null 2>&1; then
        echo "No artifacts found for target($target_info)."
        exit 1
    fi

    template_script="$RELEASE_SCRIPTS_DIR/compose-offline-packages-artifacts.sh.tmpl"
    gomplate --context .=release-router.yaml -f "$template_script" --chmod "755" --out "$out_file"

    echo "✅ Generated shell script: $out_file"
}

function install_tiup_tool() {
    local run_os="$(uname -s)"
    local run_arch="$(uname -m)"
    local tiup_ver="v1.15.2"
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

main "$@"
