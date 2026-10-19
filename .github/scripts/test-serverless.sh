#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
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
      test -f "$(yq '.artifacts[0].dockerfile' release-router.yaml)"
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
