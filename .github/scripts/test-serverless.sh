#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/kaniko" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
dockerfile= digest_file= context=
for arg in "$@"; do
  case "$arg" in
    --dockerfile=*) dockerfile=${arg#--dockerfile=} ;;
    --digest-file=*) digest_file=${arg#--digest-file=} ;;
    --context=*) context=${arg#--context=} ;;
  esac
done
grep -qxF "$dockerfile" "$EXPECTED_DOCKERFILES"
test -f "$dockerfile"
printf '%s\n' "$dockerfile" >> "$KANIKO_CALL_LOG"
case "$dockerfile" in
  */serverless/tidb-cse/*)
    # Check the actual COPY inputs, including Lightning's control binary.
    while IFS= read -r file; do
      test -f "$context/$file"
    done < <(awk '$1 == "COPY" { for (i = 2; i < NF; i++) print $i }' "$dockerfile")
    ;;
esac
printf '%s\n' 'sha256:test-digest' > "$digest_file"
EOF
cat > "$tmp/crane" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$1" = digest ]; then
  test "$2" != "${MISSING_IMAGE:-}"
  echo 'sha256:test-digest'
else
  printf '%s\n' "$*" >> "$CRANE_CALL_LOG"
fi
EOF
chmod +x "$tmp/kaniko"
chmod +x "$tmp/crane"
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
      if [ "$cm" = tidb-cse ]; then
        test "$(yq '.artifacts | length' release-router.yaml)" = 5
        grep -q 'make server build_tools build_dumpling' "$tmp/binaries.sh"
        package_source="$tmp/package-source"
        mkdir -p "$package_source/bin"
        for binary in tidb-server br dumpling tidb-lightning tidb-lightning-ctl; do
          printf '%s\n' "$binary" > "$package_source/bin/$binary"
        done
        package_dir="$tmp/packages-$arch-$registry"
        (cd "$package_source" && bash "$tmp/binaries.sh" -a -w "$package_dir")
        for binary in tidb-server br dumpling tidb-lightning tidb-lightning-ctl; do
          package=$binary
          [ "$binary" != tidb-server ] || package=tidb-cse
          archive="$package_dir/$package-$version-linux-$arch.tar.gz"
          test "$(tar -tzf "$archive")" = "$binary"
          test "$(tar -xOzf "$archive" "$binary")" = "$binary"
          test "$(sha256sum -b "$archive" | cut -d ' ' -f1)" = "$(cat "$archive.sha256")"
        done
      fi
      "$root/packages/scripts/gen-package-images-with-config.sh" "$cm" linux "$arch" "$version" release validation/Serverless aabbccddeeff1234567890abcdef1234567890abcd "" "$tmp/images.sh" "$prefix"
      shellcheck -S error "$tmp/images.sh"
      case "$cm" in
        tidb-cse) suffix=images/tidb-server ;;
        tidb-operator-cse) suffix=images/tidb-operator ;;
        *) suffix=image ;;
      esac
      test "$(yq '.artifacts[0].artifactory.repo' release-router.yaml)" = "$prefix/tidbcloud/$cm/$suffix"
      expected_dockerfiles="$tmp/expected-dockerfiles"
      printf '%s\n' "$root/dockerfiles/products/serverless/$cm/Dockerfile" > "$expected_dockerfiles"
      if [ "$cm" = tidb-cse ]; then
        test "$(yq '.artifacts | length' release-router.yaml)" = 4
        for tool in br dumpling tidb-lightning; do
          printf '%s\n' "$root/dockerfiles/products/serverless/$cm/$tool.Dockerfile" >> "$expected_dockerfiles"
          TOOL_REPO="$prefix/tidbcloud/$cm/images/$tool" yq -e '[.artifacts[] | select(.artifactory.repo == strenv(TOOL_REPO))] | length == 1' release-router.yaml
        done
      fi
      yq -r '.artifacts[].dockerfile' release-router.yaml > "$tmp/actual-dockerfiles"
      diff -u "$expected_dockerfiles" "$tmp/actual-dockerfiles"
      # Execute from a source checkout containing a decoy at the same relative path.
      # Kaniko must still receive the Dockerfile from the selected artifacts checkout.
      source_dir="$tmp/source"
      while IFS= read -r dockerfile; do
        decoy="$source_dir/${dockerfile#"$root/"}"
        mkdir -p "$(dirname "$decoy")"
        printf '%s\n' 'FROM invalid-source-dockerfile' > "$decoy"
      done < "$expected_dockerfiles"
      while IFS= read -r path; do
        mkdir -p "$source_dir/$(dirname "$path")"
        : > "$source_dir/$path"
      done < <(yq -r '.artifacts[].files[].src.path' release-router.yaml)
      : > "$tmp/kaniko-calls"
      (cd "$source_dir" && EXPECTED_DOCKERFILES="$expected_dockerfiles" KANIKO_CALL_LOG="$tmp/kaniko-calls" bash "$tmp/images.sh" -w "$tmp/build" -k "$tmp/kaniko")
      diff -u "$expected_dockerfiles" "$tmp/kaniko-calls"
      if [ "$cm" = tidb-cse ]; then
        # One missing counterpart must prevent publishing any partial manifest set.
        : > "$tmp/crane-calls"
        other_arch=arm64
        [ "$arch" != arm64 ] || other_arch=amd64
        (cd "$source_dir" && PATH="$tmp:$PATH" CRANE_CALL_LOG="$tmp/crane-calls" MISSING_IMAGE="$prefix/tidbcloud/$cm/images/br:validation-serverless-aabbccd_linux_$other_arch" bash "$tmp/images.sh" -P -m)
        test ! -s "$tmp/crane-calls"
        test "$(yq '[.images[] | select(.multi_arch_tags != null)] | length' "$source_dir/result-images.yaml")" = 0
        (cd "$source_dir" && PATH="$tmp:$PATH" CRANE_CALL_LOG="$tmp/crane-calls" bash "$tmp/images.sh" -P -m)
        test "$(grep -c '^index append ' "$tmp/crane-calls")" = 4
        test "$(yq '[.images[] | select(.multi_arch_tags != null)] | length' "$source_dir/result-images.yaml")" = 4
      fi
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
