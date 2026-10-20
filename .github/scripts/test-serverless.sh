#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/kaniko" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
dockerfile= digest_file=
for arg in "$@"; do
  case "$arg" in
    --dockerfile=*) dockerfile=${arg#--dockerfile=} ;;
    --digest-file=*) digest_file=${arg#--digest-file=} ;;
  esac
done
test "$dockerfile" = "$EXPECTED_DOCKERFILE"
test -f "$dockerfile"
printf '%s\n' 'sha256:test-digest' > "$digest_file"
EOF
chmod +x "$tmp/kaniko"
cd "$tmp"
for cm in tidb-cse pd-cse tidb-operator-cse cassandra-on-mysql qdrant-on-tidb; do
  case "$cm" in
    tidb-cse) version=v8.5.3-alpha.0 ;;
    pd-cse) version=v8.5.0-alpha.0 ;;
    tidb-operator-cse) version=v1.4.0-alpha.0 ;;
    cassandra-on-mysql) version=v0.1.0-alpha.0 ;;
    qdrant-on-tidb) version=v1.3.4-alpha.0 ;;
  esac
  for arch in amd64 arm64; do
    for registry in serverless dev; do
      prefix="us-docker.pkg.dev/pingcap-testing-account/$registry"
      builder=$("$root/packages/scripts/get-package-builder-with-config.sh" "$cm" linux "$arch" "$version" release)
      [[ "$builder" == *@sha256:* ]]
      "$root/packages/scripts/gen-package-artifacts-with-config.sh" "$cm" linux "$arch" "$version" release validation/Serverless aabbccddeeff1234567890abcdef1234567890abcd "" "$tmp/binaries.sh" "$prefix"
      shellcheck -S error "$tmp/binaries.sh"
      test "$(yq '.artifactory.package_repo' release-router.yaml)" = "$prefix/tidbcloud/$cm/package"
      test "$(yq '[.artifacts[] | select(.tiup != null)] | length' release-router.yaml)" = 0
      grep -q 'validation-serverless-aabbccd' "$tmp/binaries.sh"
      grep -q '\.sha256' "$tmp/binaries.sh"
      "$root/packages/scripts/gen-package-images-with-config.sh" "$cm" linux "$arch" "$version" release validation/Serverless aabbccddeeff1234567890abcdef1234567890abcd "" "$tmp/images.sh" "$prefix"
      shellcheck -S error "$tmp/images.sh"
      case "$cm" in
        tidb-cse) suffix=images/tidb-server ;;
        tidb-operator-cse) suffix=images/tidb-operator ;;
        *) suffix=image ;;
      esac
      test "$(yq '.artifacts[0].artifactory.repo' release-router.yaml)" = "$prefix/tidbcloud/$cm/$suffix"
      expected_dockerfile="$root/dockerfiles/products/serverless/$cm/Dockerfile"
      test "$(yq '.artifacts[0].dockerfile' release-router.yaml)" = "$expected_dockerfile"
      # Execute from a source checkout containing a decoy at the same relative path.
      # Kaniko must still receive the Dockerfile from the selected artifacts checkout.
      source_dir="$tmp/source"
      mkdir -p "$source_dir/dockerfiles/products/serverless/$cm"
      printf '%s\n' 'FROM invalid-source-dockerfile' > "$source_dir/dockerfiles/products/serverless/$cm/Dockerfile"
      while IFS= read -r path; do
        mkdir -p "$source_dir/$(dirname "$path")"
        : > "$source_dir/$path"
      done < <(yq -r '.artifacts[].files[].src.path' release-router.yaml)
      (cd "$source_dir" && EXPECTED_DOCKERFILE="$expected_dockerfile" bash "$tmp/images.sh" -w "$tmp/build" -k "$tmp/kaniko")
      grep -q "validation-serverless-aabbccd_linux_$arch" "$tmp/images.sh"
      grep -q 'crane index append' "$tmp/images.sh"
      if [ "$cm" = tidb-operator-cse ]; then
        grep -q "TARGETARCH=$arch" "$tmp/images.sh"
      fi
    done
  done
  if "$root/packages/scripts/gen-package-artifacts-with-config.sh" "$cm" darwin arm64 "$version" release main aabbccddeeff1234567890abcdef1234567890abcd "" "$tmp/invalid.sh"; then
    echo "unexpected Darwin route: $cm" >&2; exit 1
  fi
done
echo 'Serverless builders, paths, dual-platform scripts, tags and checksums passed.'
