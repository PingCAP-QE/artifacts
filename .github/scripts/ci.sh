#! /usr/bin/env bash
set -euo pipefail

# Keep empty so each component uses its own default repository URL.
readonly DEFAULT_GIT_URL=""

function check_image_existed() {
    local img=$1
    # skip the check if the image starts with "hub.pingcap.net" which is the internal image.
    if [[ $img == hub.pingcap.net* ]]; then
        return
    fi
    if crane digest $img > /dev/null; then
        echo "The image $img is existed."
    else
        echo "The image $img is not existed, please check it!"
        exit 1
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
                shellcheck -S error packages/scripts/build-package-images.sh
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
                shellcheck -S error packages/scripts/build-package-images.sh
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
                shellcheck -S error packages/scripts/build-package-images.sh
            done
        done
    done
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
            shellcheck -S error packages/scripts/build-package-images.sh
        done
    done

    # tiflow-operator
    local cm="tiflow-operator"
    for ac in $architectures; do
        for version in v6.4.0-20221102-1667359250 v20221018; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            shellcheck -S error packages/scripts/build-package-images.sh
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    for version in v0.5.0 v0.6.0; do
        for ac in $architectures; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            shellcheck -S error packages/scripts/build-package-images.sh
        done
    done

    # tiproxy
    local cm="tiproxy"
    for ac in $architectures; do
        for version in v0.1.2 v0.1.3; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            shellcheck -S error packages/scripts/build-package-images.sh
        done
    done

    # migration
    local cm="migration"
    local version="v9.0.0"
    for ac in $architectures; do
        echo -en "[📃💿] $cm $os $ac $version $profile:\t"
        $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef
        shellcheck -S error packages/scripts/build-package-images.sh
    done

    # tici. currently it only support linux.
    local cm="tici"
    for version in v0.1.0 v0.2.0; do
        for ac in $architectures; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef "" "" us-docker.pkg.dev/pingcap-testing-account/hub "$DEFAULT_GIT_URL"
            shellcheck -S error packages/scripts/build-package-images.sh
        done
    done
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
        shellcheck -S error packages/scripts/build-package-images.sh
        assert_generated_tag_without_duplicate_sha packages/scripts/build-package-images.sh "$expected_tag" "$duplicated_tag"
    done
}

function pre_checks() {
    which shellcheck || (
        echo "The script need 'shellcheck' tool, please install it!"
        exit 1
    )
}

function main() {
    pre_checks

    echo ">>>>>>>> test_get_builder >>>>>>>>>>>>>>>>>>>>>>>>"
    test_get_builder
    test_get_builder_freedom_releasing
    echo "<<<<<<<< test_get_builder <<<<<<<<<<<<<<<<<<<<<<<<"

    echo ">>>>>>>> test_gen_package_artifacts_script >>>>>>>"
    test_gen_package_artifacts_script
    test_gen_package_artifacts_script_freedom_releasing
    echo "<<<<<<<< test_gen_package_artifacts_script <<<<<<<"

    echo ">>>>>>>> test_gen_package_images_script >>>>>>>>>>"
    test_gen_package_images_script
    test_gen_package_images_script_freedom_releasing
    echo "<<<<<<<< test_gen_package_images_script <<<<<<<<<<"

    echo ">>>>>>>> test_git_tag_short_sha_dedup >>>>>>>>>>>"
    test_git_tag_short_sha_dedup
    echo "<<<<<<<< test_git_tag_short_sha_dedup <<<<<<<<<<<"

    echo ">>>> test_gen_offline_package_artifacts_script >>>"
    test_gen_offline_package_artifacts_script
    echo "<<<< test_gen_offline_package_artifacts_script <<<"
}

main "$@"
