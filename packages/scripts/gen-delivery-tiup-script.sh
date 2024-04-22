#! /usr/bin/env bash
set -eo pipefail

artifact_url="$1"
nightly="$2"
out_script="${3:-publish.sh}"

# fetch artifact config
oras manifest fetch-config "$artifact_url" >artifact-config.json
if yq -e -oy '.["net.pingcap.tibuild.tiup"] | length == 0' artifact-config.json; then
    echo "No tiup pacakges are need to published."
    exit 0
fi

tiup_last_index=$(yq --output-format=yaml '.["net.pingcap.tibuild.tiup"] | length - 1' artifact-config.json)
os=$(yq --output-format=yaml '.["net.pingcap.tibuild.os"]' artifact-config.json)
architecture=$(yq --output-format=yaml '.["net.pingcap.tibuild.architecture"]' artifact-config.json)
version=$(yq --output-format=yaml '.["org.opencontainers.image.version"]' artifact-config.json)
if [ "$nightly" == "true" ]; then
    # from vX.Y.Z-alpha-574-g75b451c454 => vX.Y.Z-alpha-nightly
    version=$(echo "$version" | sed -E 's/\-[0-9]+-g[0-9a-f]+$//')
    version="${version}-nightly"
fi

# GA case:
#   when
#   - the version is "vX.Y.Z-pre" and
#   - the artifact_url has suffix: "vX.Y.Z_(linux|darwin)_(amd64|arm64)",
#   then
#   - set the version to "vX.Y.Z"
if [[ "$version" == v[0-9]*.[0-9]*.[0-9]*-pre && "$artifact_url" =~ .*:v[0-9]*.[0-9]*.[0-9]*_(linux|darwin)_(amd64|arm64)$ ]]; then
    version="${version%-pre}"
fi

# generate the publish script.
cat <<EOF >"$out_script"
#! /usr/bin/env bash
set -eo pipefail

# check the remote file after published.
post_check() {
    remote_file_url="\$1"
    local_file="\$2"
    echo "check for remote file: \$remote_file_url"
    expected_checksum=\$(cut -d' ' -f1 <"\${local_file}.sha256")

    # Compute the actual checksum of remote file
    wget --spider "\$remote_file_url" || exit 1
    actual_checksum=\$(wget -qO- "\$remote_file_url" | sha256sum | cut -d' ' -f1)

    # Compare the checksums
    if [ "\$expected_checksum" = "\$actual_checksum" ]; then
        echo "Checksums match, file is intact."
    else
        echo "Checksums do not match, file may be corrupted."
        exit 1
    fi
}

# you should set tiup mirror firstly, i will not dealing the mirror setting and credentials in this script.

EOF

for i in $(seq 0 $tiup_last_index); do
    pkg_file="$(yq --output-format=yaml .[\"net.pingcap.tibuild.tiup\"][$i].file artifact-config.json)"
    pkg_name=$(echo "$pkg_file" | sed -E "s/-v[0-9]+.+//")
    entrypoint="$(yq --output-format=yaml .[\"net.pingcap.tibuild.tiup\"][$i].entrypoint artifact-config.json)"
    desc="$(yq --output-format=yaml .[\"net.pingcap.tibuild.tiup\"][$i].description artifact-config.json)"

    # tiup mirror publish <comp-name> <version> <tarball> <entry> [flags]
    printf "# publish $pkg_name\n" >>"$out_script"
    if yq -e -oy ".[\"net.pingcap.tibuild.tiup\"][$i].standalone" artifact-config.json; then
        printf 'tiup mirror publish %s %s %s %s --os %s --arch %s --standalone --desc "%s"\n' \
            $pkg_name $version $pkg_file $entrypoint $os $architecture "$desc" \
            >>"$out_script"
    else
        printf 'tiup mirror publish %s %s %s %s --os %s --arch %s --desc "%s"\n' \
            $pkg_name $version $pkg_file $entrypoint $os $architecture "$desc" \
            >>"$out_script"
    fi

    printf 'post_check "$(tiup mirror show)/%s-%s-%s-%s.tar.gz" "%s"\n' \
        $pkg_name $version $os $architecture $pkg_file \
        >>"$out_script"
done

echo "✅ generated script: $out_script"
