#!/usr/bin/env bash
set -euo pipefail

RELEASE_SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT_DIR=$(realpath "${RELEASE_SCRIPTS_DIR}/../..")

function normalize_profile_for_match() {
    local profile="${1:-}"
    case "$profile" in
        nextgen|next-gen)
            echo "nextgen"
            ;;
        *)
            echo "$profile"
            ;;
    esac
}

function normalize_profile_for_output() {
    local profile="${1:-}"
    case "$profile" in
        nextgen|next-gen)
            echo "nextgen"
            ;;
        *)
            echo "$profile"
            ;;
    esac
}

function main() {
    local component=$1
    local os=$2
    local arch=$3
    local version=$4
    local profile=$5
    local profile_match
    local profile_output
    local git_ref=$6
    local git_sha=$7
    local template_file="${8:-${PROJECT_ROOT_DIR}/packages/packages.yaml.tmpl}"
    local out_file="${9:-${RELEASE_SCRIPTS_DIR}/build-package-images.sh}"
    local registry="${10:-us-docker.pkg.dev/pingcap-testing-account/hub}"
    local git_url="${11:-}"
    local target_info="component: $component, os: $os, arch: $arch, version: $version, profile: $profile"

    profile_match="$(normalize_profile_for_match "$profile")"
    profile_output="$(normalize_profile_for_output "$profile")"

    if [ "$os" != "linux" ]; then
        echo "🙅 Can not build container images for os: $os, only supports linux."
        exit 1
    fi

    # prepare template file's context.
    : >release-context.yaml
    yq -i ".Release.os = \"$os\"" release-context.yaml
    yq -i ".Release.arch = \"$arch\"" release-context.yaml
    yq -i ".Release.version = \"$version\"" release-context.yaml
    yq -i ".Release.profile = \"$profile_match\"" release-context.yaml
    yq -i ".Release.registry = \"$registry\"" release-context.yaml
    yq -i ".Git.ref = \"$git_ref\"" release-context.yaml
    yq -i ".Git.sha = \"$git_sha\"" release-context.yaml
    yq -i ".Git.url = \"$git_url\"" release-context.yaml

    gomplate --context .=release-context.yaml -f "$template_file" --out release-packages.yaml
    yq ".components[\"${component}\"]" release-packages.yaml >release-package.yaml

    # filter by os and arch and release version.
    yq -i ".routers |= map(select(
            (.if == null or .if)
            and ([\"$os\"] - .os | length == 0)
            and ([\"$arch\"] - .arch | length == 0)
            and ([\"$profile_match\"] - .profile | length == 0)
        ))" release-package.yaml
    yq -i '.routers[].artifactory = .artifactory' release-package.yaml

    # fail when array length greater than 1.
    if yq -e '.routers | length > 1' release-package.yaml >/dev/null 2>&1; then
        echo "❌ Error: wrong package config that make me matched more than 1 routes!"
        exit 1
    fi

    if yq -e '.routers | length == 0' release-package.yaml >/dev/null 2>&1; then
        echo "❌ No package routes matched for the target($target_info)."
        exit 1
    fi
    yq ".routers[0].git = .git | .routers[0].license = .license" release-package.yaml | yq ".routers[0]" >release-router.yaml

    # generate package build script
    yq -i "
        .component = \"$component\" |
        .license = (.license // \"Apache-2.0\") |
        .os = \"$os\" |
        .arch = \"$arch\" |
        .profile = \"$profile_output\" |
        .profile_match = \"$profile_match\"
    " release-router.yaml
    yq -i ".steps = .steps[\"$profile_match\"]" release-router.yaml
    yq -i ".steps = (.steps | map(select(.os == null or .os == \"$os\")))" release-router.yaml
    yq -i ".steps = (.steps | map(select(.arch == null or .arch == \"$arch\")))" release-router.yaml
    yq -i '.artifacts = (.artifacts | map(select(.if == null or .if)))' release-router.yaml
    yq -i '.artifacts = (.artifacts | map(select(.type == "image")))' release-router.yaml
    yq -i ".artifacts[] |= (with(select((.context == null) and (.dockerfile | test(\"^http(s)?://\") | false)); .dockerfile = \"$PROJECT_ROOT_DIR/\" + .dockerfile))" release-router.yaml

    if yq -e '.artifacts | length == 0' release-router.yaml >/dev/null 2>&1; then
        echo "🤷 No images should be built for target($target_info)."
        exit 0
    fi

    # The multi-arch collection is atomic over the images that are built for both
    # architectures. Derive that set by rendering the same router for the other
    # architecture: images missing there are single-arch and get `multi_arch:
    # false`, so they neither block nor take part in the multi-arch collection.
    # Deriving it here keeps it in sync when the artifacts' arch conditions change.
    mark_single_arch_images "$component" "$os" "$arch" "$profile_match" "$template_file" release-router.yaml

    gomplate --context .=release-router.yaml -f "$RELEASE_SCRIPTS_DIR/build-package-images.sh.tmpl" --chmod "755" --out "$out_file"
    echo "✅ Generated shell script: $out_file"
}

function other_arch_of() {
    case "$1" in
        amd64) echo "arm64" ;;
        arm64) echo "amd64" ;;
        *) echo "" ;;
    esac
}

function mark_single_arch_images() {
    local component=$1
    local os=$2
    local arch=$3
    local profile_match=$4
    local template_file=$5
    local router_file=$6

    local other_arch
    other_arch="$(other_arch_of "$arch")"
    if [ -z "$other_arch" ]; then
        return 0
    fi

    # Render the component for the other architecture and collect its image repos.
    local other_context_file="release-context-${other_arch}.yaml"
    local other_packages_file="release-packages-${other_arch}.yaml"
    cp release-context.yaml "$other_context_file"
    yq -i ".Release.arch = \"$other_arch\"" "$other_context_file"
    gomplate --context .="$other_context_file" -f "$template_file" --out "$other_packages_file"
    rm -f "$other_context_file"

    local other_repos
    other_repos="$(
        yq -r ".components[\"${component}\"].routers[]
            | select(
                (.if == null or .if)
                and ([\"$os\"] - .os | length == 0)
                and ([\"$other_arch\"] - .arch | length == 0)
                and ([\"$profile_match\"] - .profile | length == 0)
              )
            | (.artifacts // [])[]
            | select((.if == null or .if) and .type == \"image\")
            | .artifactory.repo" "$other_packages_file" 2>/dev/null || true
    )"
    rm -f "$other_packages_file"

    local artifact_index=0
    local artifact_count
    artifact_count="$(yq '.artifacts | length' "$router_file")"
    while [ "$artifact_index" -lt "$artifact_count" ]; do
        local repo
        repo="$(yq ".artifacts[$artifact_index].artifactory.repo" "$router_file")"
        if ! printf '%s\n' "$other_repos" | grep -qxF -- "$repo"; then
            yq -i ".artifacts[$artifact_index].multi_arch = false" "$router_file"
        fi
        artifact_index=$((artifact_index + 1))
    done
}

main "$@"
