#! /usr/bin/env bash
set -euo pipefail

# Keep empty so each component uses its own default repository URL.
readonly DEFAULT_GIT_URL=""

function check_image_existed() {
    local img=$1
    if crane digest $img > /dev/null; then
        echo "The image $img is existed."
    else
        echo "The image $img is not existed, please check it!"
        exit 1
    fi
}

# The commit metadata values are optional at build time, but the generated
# scripts must always know how to emit them.
function assert_commit_metadata_support() {
    local script=$1
    local key
    for key in net.pingcap.tibuild.git-commit-title net.pingcap.tibuild.git-commit-time; do
        if ! grep -q "$key" "$script"; then
            echo "❌ $script does not emit $key"
            exit 1
        fi
    done
    echo "✅ $script emits both commit metadata keys"
}

# Check a generated release script the way the pipeline will run it.
#
# `shellcheck -S error` does not catch bash-only syntax in a `#!/bin/sh` script:
# SC3030 (`name=(...)`) and SC3054 (`"${name[@]}"`) are warnings, not errors.
# The generated build scripts really do run under a plain POSIX shell (the
# kaniko executor image only ships busybox ash), so parse them with a POSIX `sh`
# too. A script with any other shebang is bash by contract and only gets the
# pass above.
function check_generated_build_script() {
    local script=$1
    shellcheck -S error "$script"
    if [ "$(head -n 1 "$script")" != "#!/bin/sh" ]; then
        return 0
    fi
    if command -v dash > /dev/null 2>&1; then
        dash -n "$script"
    else
        sh -n "$script"
    fi
}

function test_get_builder() {
    local versions="v9.0.0 v8.5.4 v8.5.0 v8.1.0 v7.5.0 v7.1.0 v6.5.12 v6.5.11 v6.5.7-2 v6.5.0"
    local operating_systems="linux darwin"
    local architectures="amd64 arm64"
    local profile="release"
    local script="./packages/scripts/get-package-builder-with-config.sh"

    # release profile
    local components="tidb tiflow tiflash tikv pd ctl monitoring ng-monitoring tidb-tools"
    for cm in $components; do
        for version in $versions; do
            # Skip tidb-tools for version v9.0.0
            if [[ $cm == "tidb-tools" && $version == "v9.0.0" ]]; then
                echo "Skipping tidb-tools for version v9.0.0"
                continue
            fi
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo -en "[🚢] $cm $os $ac $version $profile:\t"
                    img=$($script "$cm" "$os" "$ac" "$version" "$profile" "" "" "$DEFAULT_GIT_URL")
                    echo $img
                    check_image_existed $img
                done
            done
        done
    done

    # for cdc
    local cm="ticdc"
    local versions="v8.5.4 v9.0.0"
    for version in $versions; do
        for os in $operating_systems; do
            for ac in $architectures; do
                echo -en "[🚢] $cm $os $ac $version $profile:\t"
                img=$($script "$cm" "$os" "$ac" "$version" "$profile" "" "" "$DEFAULT_GIT_URL")
                echo $img
                check_image_existed $img
            done
        done
    done

    # enterprise profile
    local components="tidb tiflash tikv pd"
    for cm in $components; do
        for version in $versions; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo -en "[🚢] $cm $os $ac $version enterprise:\t"
                    img=$($script "$cm" "$os" "$ac" "$version" enterprise "" "" "$DEFAULT_GIT_URL")
                    echo $img
                    check_image_existed $img
                done
            done
        done
    done

    # nextgen profile
    local profile="nextgen"
    local components="tidb tiflash tikv pd ticdc"
    local versions="v8.5.4 v9.0.0"
    for cm in $components; do
        for version in $versions; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo -en "[🚢] $cm $os $ac $version $profile:\t"
                    img=$($script "$cm" "$os" "$ac" "$version" $profile "" "" "$DEFAULT_GIT_URL")
                    echo $img
                    check_image_existed $img
                done
            done
        done
    done
}

##### others that owns theirs non-unified versions #####
function test_get_builder_freedom_releasing() {
    local operating_systems="linux darwin"
    local architectures="amd64 arm64"
    local script="./packages/scripts/get-package-builder-with-config.sh"

    # tidb-operator
    local cm="tidb-operator"
    local profile="release"
    local os="linux"
    for ac in $architectures; do
        for version in v2.0.0 v1.6.0 v1.5.0; do
            echo -en "[🚢] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile "" "" "$DEFAULT_GIT_URL"
        done
    done

    # tiflow-operator
    local cm="tiflow-operator"
    local profile="release"
    local os="linux"
    for ac in $architectures; do
        for version in v6.4.0-20221102-1667359250 v20221018; do
            echo -en "[🚢] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile "" "" "$DEFAULT_GIT_URL"
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for ac in $architectures; do
        for version in v0.5.0 v0.6.0; do
            echo -en "[🚢] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile "" "" "$DEFAULT_GIT_URL"
        done
    done

    # tiproxy
    local cm="tiproxy"
    for os in $operating_systems; do
        for ac in $architectures; do
            for version in v0.1.2 v0.1.3; do
                echo -en "[🚢] $cm $os $ac $version $profile:\t"
                $script "$cm" "$os" "$ac" "$version" $profile "" "" "$DEFAULT_GIT_URL"
            done
        done
    done

    # migration
    local cm="migration"
    local os="linux"
    local version="v9.0.0"
    for ac in $architectures; do
        echo -en "[🚢] $cm $os $ac $version $profile:\t"
        img=$($script "$cm" "$os" "$ac" "$version" $profile)
        echo $img
        check_image_existed $img
    done

    # tici, currently it only support linux.
    local cm="tici"
    for os in linux; do
        for ac in $architectures; do
            for version in v0.1.0 v0.2.0; do
                echo -en "[🚢] $cm $os $ac $version $profile:\t"
                $script "$cm" "$os" "$ac" "$version" $profile "" "" "$DEFAULT_GIT_URL"
            done
        done
    done
}

function test_gen_package_artifacts_script() {
    local versions="v9.0.0 v8.5.4 v8.5.0 v8.1.0 v7.5.0 v7.1.0 v6.5.12 v6.5.11 v6.5.7-2 v6.5.0"
    local operating_systems="linux darwin"
    local architectures="amd64 arm64"
    local script="./packages/scripts/gen-package-artifacts-with-config.sh"

    # release profile
    local profile="release"
    local components="tidb tiflow tiflash tikv pd ctl monitoring ng-monitoring tidb-tools"
    for cm in $components; do
        for version in $versions; do
            # Skip tidb-tools for version v9.0.0
            if [[ $cm == "tidb-tools" && $version == "v9.0.0" ]]; then
                echo "Skipping tidb-tools for version v9.0.0"
                continue
            fi
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo -en "[📃📦] $cm $os $ac $version $profile:\t"
                    $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
                    shellcheck -S error packages/scripts/build-package-artifacts.sh
                done
            done
        done
    done

    # enterprise profile
    local profile="enterprise"
    local components="tidb tikv pd tiflash"
    for cm in $components; do
        for version in $versions; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo -en "[📃📦] $cm $os $ac $version $profile:\t"
                    $script "$cm" "$os" "$ac" "$version" enterprise branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
                    shellcheck -S error packages/scripts/build-package-artifacts.sh
                done
            done
        done
    done

    # failpoint profile
    local profile="failpoint"
    local components="tidb tikv pd"
    for cm in $components; do
        for version in $versions; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo -en "[📃📦] $cm $os $ac $version $profile:\t"
                    $script "$cm" "$os" "$ac" "$version" failpoint branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
                    shellcheck -S error packages/scripts/build-package-artifacts.sh
                done
            done
        done
    done

    # nextgen profile
    local profile="nextgen"
    local components="tidb tikv pd ticdc tiflash"
    local versions="v9.0.0 v8.5.4"
    for cm in $components; do
        for version in $versions; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo -en "[📃📦] $cm $os $ac $version $profile:\t"
                    $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
                    shellcheck -S error packages/scripts/build-package-artifacts.sh
                done
            done
        done
    done
    assert_commit_metadata_support packages/scripts/build-package-artifacts.sh
}

##### others that owns theirs non-unified versions #####
function test_gen_package_artifacts_script_freedom_releasing() {
    local operating_systems="linux darwin"
    local architectures="amd64 arm64"
    local profile="release"
    local script="./packages/scripts/gen-package-artifacts-with-config.sh"

    # tidb-operator
    local cm="tidb-operator"
    local os="linux"
    for ac in $architectures; do
        for version in v2.0.0 v1.6.0 v1.5.0; do
            echo -en "[📃📦] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            shellcheck -S error packages/scripts/build-package-artifacts.sh
        done
    done

    # tiflow-operator
    local cm="tiflow-operator"
    local os="linux"
    for ac in $architectures; do
        for version in v6.4.0-20221102-1667359250 v20221018; do
            echo -en "[📃📦] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            shellcheck -S error packages/scripts/build-package-artifacts.sh
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for ac in $architectures; do
        for version in v0.5.0 v0.6.0; do
            echo -en "[📃📦] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            shellcheck -S error packages/scripts/build-package-artifacts.sh
        done
    done

    # tiproxy
    local cm="tiproxy"
    local os="linux"
    for ac in $architectures; do
        for version in v0.1.2 v0.1.3; do
            echo -en "[📃📦] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            shellcheck -S error packages/scripts/build-package-artifacts.sh
        done
    done

    # tici, currently it only support linux.
    local cm="tici"
    local os="linux"
    for ac in $architectures; do
        for version in v0.1.0 v0.2.0; do
            echo -en "[📃📦] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            shellcheck -S error packages/scripts/build-package-artifacts.sh
        done
    done
}

# Extract the body of the multi-arch collection function from a generated build script.
function extract_multi_arch_body() {
    local script_path=$1
    awk '/^collect_and_push_multi_arch_images\(\) \{/{f=1} f{print} f&&/^\}/{exit}' "$script_path"
}

function assert_image_in_multi_arch() {
    local script_path=$1
    local repo=$2
    local body
    body="$(extract_multi_arch_body "$script_path")"
    if ! grep -qF -- "$repo" <<<"$body"; then
        echo "❌ Repo '$repo' should take part in the multi-arch collection of $script_path"
        exit 1
    fi
}

function assert_image_excluded_from_multi_arch() {
    local script_path=$1
    local repo=$2
    local body
    body="$(extract_multi_arch_body "$script_path")"
    if grep -qF -- "$repo" <<<"$body"; then
        echo "❌ Repo '$repo' should be excluded from the multi-arch collection of $script_path"
        exit 1
    fi
}

function test_gen_package_images_script() {
    local versions="v9.0.0 v8.5.4 v8.5.0 v8.1.0 v7.5.0 v7.1.0 v6.5.12 v6.5.11 v6.5.7-2 v6.5.0 v6.1.0"
    local os="linux"
    local architectures="amd64 arm64"
    local script="./packages/scripts/gen-package-images-with-config.sh"

    # release profile
    local profile="release"
    local components="tidb tiflow tiflash tikv pd ctl monitoring ng-monitoring tidb-tools"
    for cm in $components; do
        for version in $versions; do
            # Skip tidb-tools for version v9.0.0
            if [[ $cm == "tidb-tools" && $version == "v9.0.0" ]]; then
                echo "Skipping tidb-tools for version v9.0.0"
                continue
            fi
            for ac in $architectures; do
                echo -en "[📃💿] $cm $os $ac $version $profile:\t"
                $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
                check_generated_build_script packages/scripts/build-package-images.sh
            done
        done
    done

    # ticdc release images. The amd64-only test tools are auto-excluded from the atomic multi-arch collection.
    local cm="ticdc"
    local cdc_image="us-docker.pkg.dev/pingcap-testing-account/hub/pingcap/ticdc/image"
    local ticdc_test_images=(
        "us-docker.pkg.dev/pingcap-testing-account/hub/pingcap/ticdc/test-images/kafka-consumer"
        "us-docker.pkg.dev/pingcap-testing-account/hub/pingcap/ticdc/test-images/pulsar-consumer"
        "us-docker.pkg.dev/pingcap-testing-account/hub/pingcap/ticdc/test-images/storage-consumer"
    )
    local ticdc_versions="v8.5.4 v9.0.0"
    for version in $ticdc_versions; do
        for ac in $architectures; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            check_generated_build_script packages/scripts/build-package-images.sh
            assert_image_in_multi_arch packages/scripts/build-package-images.sh "$cdc_image"
            local test_image
            for test_image in "${ticdc_test_images[@]}"; do
                assert_image_excluded_from_multi_arch packages/scripts/build-package-images.sh "$test_image"
            done
        done
    done

    # enterprise profile
    local profile="enterprise"
    local components="tidb tikv pd tiflash"
    for cm in $components; do
        for version in $versions; do
            for ac in $architectures; do
                echo -en "[📃💿] $cm $os $ac $version $profile:\t"
                $script $cm $os $ac $version $profile branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
                check_generated_build_script packages/scripts/build-package-images.sh
            done
        done
    done

    # nextgen profile
    local profile="nextgen"
    local versions="v9.0.0 v8.5.4"
    local components="tidb tikv pd tiflash ticdc"
    for cm in $components; do
        for version in $versions; do
            for ac in $architectures; do
                echo -en "[📃💿] $cm $os $ac $version $profile:\t"
                $script $cm $os $ac $version $profile branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
                check_generated_build_script packages/scripts/build-package-images.sh
            done
        done
    done
    assert_commit_metadata_support packages/scripts/build-package-images.sh
}

function test_gen_package_images_script_freedom_releasing() {
    local os="linux"
    local architectures="amd64 arm64"
    local profile="release"
    local script="./packages/scripts/gen-package-images-with-config.sh"

    ##### others that owns theirs non-unified versions #####
    # tidb-operator
    local cm="tidb-operator"
    for ac in $architectures; do
        for version in v2.0.0 v1.6.0 v1.5.0; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            check_generated_build_script packages/scripts/build-package-images.sh
        done
    done

    # tiflow-operator
    local cm="tiflow-operator"
    for ac in $architectures; do
        for version in v6.4.0-20221102-1667359250 v20221018; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            check_generated_build_script packages/scripts/build-package-images.sh
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    for version in v0.5.0 v0.6.0; do
        for ac in $architectures; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            check_generated_build_script packages/scripts/build-package-images.sh
        done
    done

    # tiproxy
    local cm="tiproxy"
    for ac in $architectures; do
        for version in v0.1.2 v0.1.3; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            check_generated_build_script packages/scripts/build-package-images.sh
        done
    done

    # migration
    local cm="migration"
    local version="v9.0.0"
    for ac in $architectures; do
        echo -en "[📃💿] $cm $os $ac $version $profile:\t"
        $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef
        check_generated_build_script packages/scripts/build-package-images.sh
    done

    # tici. currently it only support linux.
    local cm="tici"
    for version in v0.1.0 v0.2.0; do
        for ac in $architectures; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            check_generated_build_script packages/scripts/build-package-images.sh
        done
    done
}

# Run the generated image script the way the pipeline runs it: inside the kaniko
# executor image, which ships no git. The commit metadata has to come from the
# caller's environment there, otherwise both labels disappear without any error.
function test_images_commit_metadata_from_env() {
    local tmp
    tmp="$(mktemp -d)"
    local script="$tmp/build-package-images.sh"

    ./packages/scripts/gen-package-images-with-config.sh \
        tikv linux amd64 v9.0.0 nextgen branch-xxx 123456789abcdef "" "$script" \
        us-docker.pkg.dev/pingcap-testing-account/tidbx "$DEFAULT_GIT_URL" > /dev/null
    check_generated_build_script "$script"

    # Minimal build context and hermetic fakes: no registry, no network.
    mkdir -p "$tmp/src/bin" "$tmp/release" "$tmp/fakes"
    : > "$tmp/src/bin/tikv-server"
    : > "$tmp/src/bin/cse-ctl"
    : > "$tmp/src/bin/tikv-worker"

    cat > "$tmp/fakes/kaniko" <<'FAKE_KANIKO'
#!/bin/sh
printf '%s\n' "$@" > "$KANIKO_ARGS_FILE"
for arg in "$@"; do
    case "$arg" in
        --digest-file=*) printf 'sha256:0123456789abcdef\n' > "${arg#--digest-file=}" ;;
    esac
done
FAKE_KANIKO
    cat > "$tmp/fakes/wget" <<'FAKE_WGET'
#!/bin/sh
out_file=""
while [ "$#" -gt 0 ]; do
    if [ "$1" = "-O" ]; then
        out_file="$2"
        shift 2
        continue
    fi
    shift
done
[ -n "$out_file" ] || exit 1
printf 'FROM scratch\n' > "$out_file"
FAKE_WGET
    chmod +x "$tmp/fakes/kaniko" "$tmp/fakes/wget"

    echo -en "[📃💿] image script without commit metadata:\t"
    (
        cd "$tmp/src" || exit 1
        env -u COMMIT_TITLE -u COMMIT_TIME PATH="$tmp/fakes:$PATH" \
            KANIKO_ARGS_FILE="$tmp/kaniko-args-empty.txt" \
            sh "$script" -w "$tmp/release" -k "$tmp/fakes/kaniko" -o "$tmp/pushed-empty.yaml"
    )
    if grep -qF -- "--label=net.pingcap.tibuild.git-commit-" "$tmp/kaniko-args-empty.txt"; then
        echo "❌ commit metadata labels must be omitted when the caller provides none and git is unavailable"
        exit 1
    fi

    echo -en "[📃💿] image script with exported commit metadata:\t"
    (
        cd "$tmp/src" || exit 1
        env PATH="$tmp/fakes:$PATH" \
            KANIKO_ARGS_FILE="$tmp/kaniko-args-env.txt" \
            COMMIT_TITLE="  tests,cloud_worker: keep   worker configs  " \
            COMMIT_TIME="2026-11-09T11:13:02Z" \
            sh "$script" -w "$tmp/release" -k "$tmp/fakes/kaniko" -o "$tmp/pushed-env.yaml"
    )
    local expected
    for expected in \
        "--label=net.pingcap.tibuild.git-commit-title=tests,cloud_worker: keep   worker configs" \
        "--label=net.pingcap.tibuild.git-commit-time=2026-11-09T11:13:02Z"; do
        if ! grep -qxF -- "$expected" "$tmp/kaniko-args-env.txt"; then
            echo "❌ kaniko argv of the image script is missing the single argument '$expected'"
            exit 1
        fi
    done
    echo "✅ both commit metadata labels come from the environment as single argv entries"

    rm -rf "$tmp"
}

function test_gen_offline_package_artifacts_script() {
    local versions="v9.0.0 v8.5.0 v8.1.0 v8.0.0 v7.5.0 v7.1.0 v6.5.12 v6.5.11 v6.5.7-2 v6.5.0 v6.1.0"
    local operating_systems="linux"
    local architectures="amd64 arm64"
    local editions="community enterprise dm"
    local script="./packages/scripts/gen-package-offline-package-with-config.sh"

    for version in $versions; do
        for os in $operating_systems; do
            for ac in $architectures; do
                for edition in $editions; do
                    echo "$os $ac $version $edition:"
                    $script "$os" "$ac" "$version" "$edition"
                    shellcheck -S error packages/scripts/compose-offline-packages-artifacts.sh
                done
            done
        done
    done
}

function assert_generated_tag_without_duplicate_sha() {
    local script_path=$1
    local expected_tag=$2
    local duplicated_tag=$3

    if ! grep -qF -- "$expected_tag" "$script_path"; then
        echo "Expected tag '$expected_tag' not found in $script_path"
        exit 1
    fi

    if grep -qF -- "$duplicated_tag" "$script_path"; then
        echo "Duplicated tag '$duplicated_tag' unexpectedly found in $script_path"
        exit 1
    fi
}

function test_git_tag_short_sha_dedup() {
    local component="tidb"
    local os="linux"
    local arch="amd64"
    local profile="release"
    local git_sha="bfa749d1234567890abcdef1234567890abcd"
    local registry="us-docker.pkg.dev/pingcap-testing-account/hub"
    local image_script="./packages/scripts/gen-package-images-with-config.sh"
    local artifact_script="./packages/scripts/gen-package-artifacts-with-config.sh"
    local cases=(
        "v8.5.6-20260331-bfa749d|v8.5.6-20260331-bfa749d|v8.5.6-20260331-bfa749d-bfa749d"
        "v26.3.1-2-gbfa749d|v26.3.1-2-gbfa749d|v26.3.1-2-gbfa749d-bfa749d"
    )

    for test_case in "${cases[@]}"; do
        IFS='|' read -r git_ref expected_tag duplicated_tag <<< "$test_case"

        echo -en "[🏷️📦] $component $git_ref:\t"
        "$artifact_script" "$component" "$os" "$arch" "$git_ref" "$profile" "$git_ref" "$git_sha" "" "" "$registry" "$DEFAULT_GIT_URL"
        shellcheck -S error packages/scripts/build-package-artifacts.sh
        assert_generated_tag_without_duplicate_sha packages/scripts/build-package-artifacts.sh "$expected_tag" "$duplicated_tag"

        echo -en "[🏷️💿] $component $git_ref:\t"
        "$image_script" "$component" "$os" "$arch" "$git_ref" "$profile" "$git_ref" "$git_sha" "" "" "$registry" "$DEFAULT_GIT_URL"
        check_generated_build_script packages/scripts/build-package-images.sh
        assert_generated_tag_without_duplicate_sha packages/scripts/build-package-images.sh "$expected_tag" "$duplicated_tag"
    done
}

# The delivery generator turns the build stage's image list plus the delivery
# rules into the `crane` commands the delivery job runs with push credentials.
# Both inputs are data from other stages, so a value outside the expected
# character set, a permissive rule or a hostile destination must stop the run
# instead of being quoted into the emitted script.
function test_gen_delivery_image_commands() {
    local script="./packages/scripts/gen-delivery-image-commands.ts"
    local work
    work="$(mktemp -d)"
    # shellcheck disable=SC2064 # expand $work now, the trap runs after it is gone
    trap "rm -rf '$work'" RETURN

    if ! command -v deno > /dev/null 2>&1; then
        echo "🤷 deno not found; skipping the delivery generator checks."
        return 0
    fi

    if ! deno check "$script" packages/scripts/lib/delivery-config.ts packages/scripts/get-delivery-target-images.ts > /dev/null 2>&1; then
        echo "❌ the delivery scripts do not type-check"
        exit 1
    fi
    echo "✅ delivery scripts type-check"

    local valid_rules="$work/delivery.yaml"
    cat > "$valid_rules" << 'YAML'
image_copy_rules:
  "us-docker.pkg.dev/hub/pingcap/tidb/image":
    - description: "next-gen trunk rule"
      tags_regex: ["^(master|dedicated)(-.*)?-nextgen$"]
      dest_repositories: ["docker.io/pingcap/tidb"]
      constant_tags: ["latest"]
YAML

    local valid_images="$work/images.yaml"
    cat > "$valid_images" << 'YAML'
images:
  - repo: "us-docker.pkg.dev/hub/pingcap/tidb/image"
    tag: "master-nextgen"
YAML

    # A tag that carries shell metacharacters must be refused before it reaches
    # the emitted script, even if a permissive rule would match it.
    local hostile_images="$work/hostile-images.yaml"
    cat > "$hostile_images" << 'YAML'
images:
  - repo: "us-docker.pkg.dev/hub/pingcap/tidb/image"
    tag: "master-$(id)-nextgen"
YAML

    # A rule whose destination is a shell fragment must be refused: the rules are
    # policy, and the policy must not be able to become code.
    local hostile_dest_rules="$work/hostile-dest.yaml"
    cat > "$hostile_dest_rules" << 'YAML'
image_copy_rules:
  "us-docker.pkg.dev/hub/pingcap/tidb/image":
    - tags_regex: ["^master-nextgen$"]
      dest_repositories: ["docker.io/pingcap/tidb; id"]
YAML

    # An oversized or quadratic rule regex must be refused too.
    local hostile_regex_rules="$work/hostile-regex.yaml"
    cat > "$hostile_regex_rules" << 'YAML'
image_copy_rules:
  "us-docker.pkg.dev/hub/pingcap/tidb/image":
    - tags_regex: ["^(a+)+-nextgen$"]
      dest_repositories: ["docker.io/pingcap/tidb"]
YAML

    local status out
    out="$work/delivery-images.sh"

    local case_name
    for case_name in "hostile tag:hostile_images:valid_rules" "hostile destination:valid_images:hostile_dest_rules" "quadratic regex:valid_images:hostile_regex_rules"; do
        local label="${case_name%%:*}"
        local rest="${case_name#*:}"
        local images_var="${rest%%:*}"
        local rules_var="${rest##*:}"
        rm -f "$out"
        status=0
        deno run --allow-read --allow-write "$script" \
            --images_file="${!images_var}" \
            --yaml_file="${!rules_var}" \
            --outfile="$out" \
            --images_outfile="$work/targets.yaml" > /dev/null 2>&1 || status=$?
        if [ "$status" -ne 2 ]; then
            echo "❌ delivery generator ($label): expected exit 2, got $status"
            exit 1
        fi
        if [ -e "$out" ]; then
            echo "❌ delivery generator ($label): rejected the input but wrote $out"
            exit 1
        fi
        echo "✅ delivery generator ($label): rejected, no script written"
    done

    status=0
    deno run --allow-read --allow-write "$script" \
        --images_file="$valid_images" \
        --yaml_file="$valid_rules" \
        --outfile="$out" \
        --images_outfile="$work/targets.yaml" > /dev/null 2>&1 || status=$?
    if [ "$status" -ne 0 ] || [ ! -s "$out" ]; then
        echo "❌ delivery generator: valid input produced no script (exit $status)"
        exit 1
    fi
    sh -n "$out"
    if ! grep -qE "^crane copy '[^']*' '[^']*'$" "$out"; then
        echo "❌ delivery generator: crane commands are not fully quoted"
        exit 1
    fi
    if ! grep -qE "^crane tag '[^']*' 'latest'$" "$out"; then
        echo "❌ delivery generator: constant tag command is not quoted"
        exit 1
    fi
    echo "✅ delivery generator: valid input produced a quoted, POSIX-clean script"
}

function pre_checks() {
    which shellcheck || (
        echo "The script need 'shellcheck' tool, please install it!"
        exit 1
    )
}

function main() {
    pre_checks
    # Reject hostile generator inputs before the long matrix below.
    ./packages/scripts/verify-input-validation.sh
    ./.github/scripts/test-serverless.sh

    echo ">>>>>>>> test_get_builder >>>>>>>>>>>>>>>>>>>>>>>>"
    test_get_builder
    test_get_builder_freedom_releasing
    echo "<<<<<<<< test_get_builder <<<<<<<<<<<<<<<<<<<<<<<<"

    echo ">>>>>>>> verify_macos_tools_coverage >>>>>>>>>>>>"
    ./packages/scripts/verify-macos-tools-coverage.sh
    echo "<<<<<<<< verify_macos_tools_coverage <<<<<<<<<<<<"

    echo ">>>>>>>> test_gen_package_artifacts_script >>>>>>>"
    test_gen_package_artifacts_script
    test_gen_package_artifacts_script_freedom_releasing
    echo "<<<<<<<< test_gen_package_artifacts_script <<<<<<<"

    echo ">>>>>>>> test_gen_package_images_script >>>>>>>>>>"
    test_gen_package_images_script
    test_gen_package_images_script_freedom_releasing
    test_images_commit_metadata_from_env
    echo "<<<<<<<< test_gen_package_images_script <<<<<<<<<<"

    echo ">>>>>>>> test_git_tag_short_sha_dedup >>>>>>>>>>>"
    test_git_tag_short_sha_dedup
    echo "<<<<<<<< test_git_tag_short_sha_dedup <<<<<<<<<<<"

    echo ">>>>>>>> test_gen_delivery_image_commands >>>>>>>"
    test_gen_delivery_image_commands
    echo "<<<<<<<< test_gen_delivery_image_commands <<<<<<<<"

    echo ">>>> test_gen_offline_package_artifacts_script >>>"
    test_gen_offline_package_artifacts_script
    echo "<<<< test_gen_offline_package_artifacts_script <<<"
}

main "$@"
