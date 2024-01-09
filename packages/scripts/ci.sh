#! /usr/bin/env bash
set -euo pipefail

function test_get_builder() {
    local versions="v7.5.0 v7.1.0 v6.5.0"
    local components="tidb tiflow tiflash tikv pd ctl monitoring tidb-binlog tidb-tools"
    local operating_systems="linux darwin"
    local architectures="amd64 arm64"
    local profile="release"
    local script="./packages/scripts/get-package-builder-with-config.sh"

    for version in $versions; do
        for cm in $components; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo "$cm $os $ac $version:"
                    $script $cm $os $ac $version $profile
                done
            done
        done
    done

    # tidb enterprise profile
    local cm="tidb"
    for version in $versions; do
        for os in $operating_systems; do
            for ac in $architectures; do
                echo "$cm $os $ac $version:"
                $script $cm $os $ac $version $profile
            done
        done
    done

    ##### others that owns theirs non-unified versions #####
    # tidb-operator
    local cm="tidb-operator"
    local os="linux"
    for ac in $architectures; do
        for version in v1.5.0 v1.6.0; do
            echo "$cm $os $ac $version:"
            $script $cm $os $ac $version $profile
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for ac in $architectures; do
        for version in v0.5.0 v0.6.0; do
            echo "$cm $os $ac $version:"
            $script $cm $os $ac $version $profile
        done
    done

    # tiproxy
    local cm="tiproxy"
    local os="linux"
    for ac in $architectures; do
        for version in v0.1.2 v0.1.3; do
            echo "$cm $os $ac $version:"
            $script $cm $os $ac $version $profile
        done
    done
}

function test_gen_package_artifacts_script() {
    local versions="v7.5.0 v7.1.0 v6.5.0"
    local components="tidb tiflow tiflash tikv pd ctl monitoring tidb-binlog tidb-tools"
    local operating_systems="linux darwin"
    local architectures="amd64 arm64"
    local profile="release"
    local script="./packages/scripts/gen-package-artifacts-with-config.sh"

    for version in $versions; do
        for cm in $components; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo "$cm $os $ac $version:"
                    $script $cm $os $ac $version $profile branch-xxx 123456789abcdef
                done
            done
        done
    done

    # tidb enterprise profile
    local cm="tidb"
    for version in $versions; do
        for os in $operating_systems; do
            for ac in $architectures; do
                echo "$cm $os $ac $version:"
                $script $cm $os $ac $version $profile branch-xxx 123456789abcdef
            done
        done
    done

    ##### others that owns theirs non-unified versions #####
    # tidb-operator
    local cm="tidb-operator"
    local os="linux"
    for ac in $architectures; do
        for version in v1.5.0 v1.6.0; do
            echo "$cm $os $ac $version:"
            $script $cm $os $ac $version $profile branch-xxx 123456789abcdef
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for ac in $architectures; do
        for version in v0.5.0 v0.6.0; do
            echo "$cm $os $ac $version:"
            $script $cm $os $ac $version $profile branch-xxx 123456789abcdef
        done
    done

    # tiproxy
    local cm="tiproxy"
    local os="linux"
    for ac in $architectures; do
        for version in v0.1.2 v0.1.3; do
            echo "$cm $os $ac $version:"
            $script $cm $os $ac $version $profile branch-xxx 123456789abcdef
        done
    done
}

function test_gen_package_images_script() {
    local versions="v7.5.0 v7.1.0 v6.5.0"
    local components="tidb tiflow tiflash tikv pd ctl monitoring tidb-binlog tidb-tools"
    local architectures="amd64 arm64"
    local profile="release"
    local script="./packages/scripts/gen-package-images-with-config.sh"

    for version in $versions; do
        for cm in $components; do
            for ac in $architectures; do
                echo "$cm $os $ac $version:"
                $script $cm linux $ac $version $profile branch-xxx 123456789abcdef
            done
        done
    done

    # tidb enterprise profile
    local cm="tidb"
    for version in $versions; do
        for ac in $architectures; do
            echo "$cm $os $ac $version:"
            $script $cm linux $ac $version $profile branch-xxx 123456789abcdef
        done
    done

    ##### others that owns theirs non-unified versions #####
    # tidb-operator
    local cm="tidb-operator"
    local os="linux"
    for ac in $architectures; do
        for version in v1.6.0 v1.5.0; do
            echo "$cm $os $ac $version:"
            $script $cm linux $ac $version $profile branch-xxx 123456789abcdef
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for version in v0.5.0 v0.6.0; do
        for ac in $architectures; do
            echo "$cm $os $ac $version:"
            $script $cm linux $ac $version $profile branch-xxx 123456789abcdef
        done
    done

    # tiproxy
    local cm="tiproxy"
    local os="linux"
    for ac in $architectures; do
        for version in v0.1.2 v0.1.3; do
            echo "$cm $os $ac $version:"
            $script $cm linux $ac $version $profile branch-xxx 123456789abcdef
        done
    done
}

function test_gen_offline_package_artifacts_script() {
    local versions="v7.5.0 v7.1.0"
    local operating_systems="linux"
    local architectures="amd64 arm64"
    local editions="community"
    local script="./packages/scripts/gen-package-offline-package-with-config.sh"

    for version in $versions; do
        for os in $operating_systems; do
            for ac in $architectures; do
                for edition in $editions; do
                    echo "$os $ac $version $edition:"
                    $script $os $ac $version $edition
                done
            done
        done
    done
}

function main() {
    echo ">>>>>>>> test_get_builder >>>>>>>>>>>>>>>>>>>>>>>>"
    test_get_builder
    echo "<<<<<<<< test_get_builder <<<<<<<<<<<<<<<<<<<<<<<<"

    echo ">>>>>>>> test_gen_package_artifacts_script >>>>>>>"
    test_gen_package_artifacts_script
    echo "<<<<<<<< test_gen_package_artifacts_script <<<<<<<"

    echo ">>>>>>>> test_gen_package_images_script >>>>>>>>>>"
    test_gen_package_images_script
    echo "<<<<<<<< test_gen_package_images_script <<<<<<<<<<"

    echo ">>>> test_gen_offline_package_artifacts_script >>>"
    test_gen_offline_package_artifacts_script
    echo "<<<< test_gen_offline_package_artifacts_script <<<"
}

main "$@"
