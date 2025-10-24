#! /usr/bin/env bash
set -euo pipefail

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
                    img=$($script "$cm" "$os" "$ac" "$version" "$profile")
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
                img=$($script "$cm" "$os" "$ac" "$version" "$profile")
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
                    img=$($script "$cm" "$os" "$ac" "$version" enterprise)
                    echo $img
                    check_image_existed $img
                done
            done
        done
    done

    # next-gen profile
    local profile="next-gen"
    local components="tidb tiflash tikv pd ticdc"
    for cm in $components; do
        for version in "v8.5.4 v9.0.0"; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo -en "[🚢] $cm $os $ac $version $profile:\t"
                    img=$($script "$cm" "$os" "$ac" "$version" $profile)
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
            $script "$cm" "$os" "$ac" "$version" $profile
        done
    done

    # tiflow-operator
    local cm="tiflow-operator"
    local profile="release"
    local os="linux"
    for ac in $architectures; do
        for version in v6.4.0-20221102-1667359250 v20221018; do
            echo -en "[🚢] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for ac in $architectures; do
        for version in v0.5.0 v0.6.0; do
            echo -en "[🚢] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile
        done
    done

    # tiproxy
    local cm="tiproxy"
    for os in $operating_systems; do
        for ac in $architectures; do
            for version in v0.1.2 v0.1.3; do
                echo -en "[🚢] $cm $os $ac $version $profile:\t"
                $script "$cm" "$os" "$ac" "$version" $profile
            done
        done
    done

    # tici, currently it only support linux.
    local cm="tici"
    for os in linux; do
        for ac in $architectures; do
            for version in v0.1.0 v0.2.0; do
                echo -en "[🚢] $cm $os $ac $version $profile:\t"
                $script "$cm" "$os" "$ac" "$version" $profile
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
                    $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef
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
                    $script "$cm" "$os" "$ac" "$version" enterprise branch-xxx 123456789abcdef
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
                    $script "$cm" "$os" "$ac" "$version" failpoint branch-xxx 123456789abcdef
                    shellcheck -S error packages/scripts/build-package-artifacts.sh
                done
            done
        done
    done

    # next-gen profile
    local profile="next-gen"
    local components="tidb tikv pd ticdc tiflash"
    local versions="v9.0.0 v8.5.4"
    for cm in $components; do
        for version in $versions; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo -en "[📃📦] $cm $os $ac $version $profile:\t"
                    $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef
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
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef
            shellcheck -S error packages/scripts/build-package-artifacts.sh
        done
    done

    # tiflow-operator
    local cm="tiflow-operator"
    local os="linux"
    for ac in $architectures; do
        for version in v6.4.0-20221102-1667359250 v20221018; do
            echo -en "[📃📦] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef
            shellcheck -S error packages/scripts/build-package-artifacts.sh
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for ac in $architectures; do
        for version in v0.5.0 v0.6.0; do
            echo -en "[📃📦] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef
            shellcheck -S error packages/scripts/build-package-artifacts.sh
        done
    done

    # tiproxy
    local cm="tiproxy"
    local os="linux"
    for ac in $architectures; do
        for version in v0.1.2 v0.1.3; do
            echo -en "[📃📦] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef
            shellcheck -S error packages/scripts/build-package-artifacts.sh
        done
    done

    # tici, currently it only support linux.
    local cm="tici"
    local os="linux"
    for ac in $architectures; do
        for version in v0.1.0 v0.2.0; do
            echo -en "[📃📦] $cm $os $ac $version $profile:\t"
            $script "$cm" "$os" "$ac" "$version" $profile branch-xxx 123456789abcdef
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
                $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef
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
                $script $cm $os $ac $version $profile branch-xxx 123456789abcdef
                shellcheck -S error packages/scripts/build-package-images.sh
            done
        done
    done

    # next-gen profile
    local profile="next-gen"
    local components="tidb tikv pd tiflash ticdc"
    for cm in $components; do
        for version in $versions; do
            for ac in $architectures; do
                echo -en "[📃💿] $cm $os $ac $version $profile:\t"
                $script $cm $os $ac $version $profile branch-xxx 123456789abcdef
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
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef
            shellcheck -S error packages/scripts/build-package-images.sh
        done
    done

    # tiflow-operator
    local cm="tiflow-operator"
    for ac in $architectures; do
        for version in v6.4.0-20221102-1667359250 v20221018; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef
            shellcheck -S error packages/scripts/build-package-images.sh
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    for version in v0.5.0 v0.6.0; do
        for ac in $architectures; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef
            shellcheck -S error packages/scripts/build-package-images.sh
        done
    done

    # tiproxy
    local cm="tiproxy"
    for ac in $architectures; do
        for version in v0.1.2 v0.1.3; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef
            shellcheck -S error packages/scripts/build-package-images.sh
        done
    done

    # tici. currently it only support linux.
    local cm="tici"
    for version in v0.1.0 v0.2.0; do
        for ac in $architectures; do
            echo -en "[📃💿] $cm $os $ac $version $profile:\t"
            $script "$cm" linux "$ac" "$version" "$profile" branch-xxx 123456789abcdef
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

    echo ">>>> test_gen_offline_package_artifacts_script >>>"
    test_gen_offline_package_artifacts_script
    echo "<<<< test_gen_offline_package_artifacts_script <<<"
}

main "$@"
