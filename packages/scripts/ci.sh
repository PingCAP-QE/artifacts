#! /usr/bin/env bash
set -euo pipefail

function test_get_builder() {
    local versions="v7.5.0 v7.1.0 v6.5.0 v6.1.0"
    local components="tidb tiflow tiflash tikv pd ctl"
    local operating_systems="linux darwin"
    local architectures="amd64 arm64"
    local profile="release"

    for version in $versions; do
        for cm in $components; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo "$cm $os $ac $version:"
                    ./packages/scripts/get-package-builder-with-config.sh $cm $os $ac $version $profile
                done
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
            ./packages/scripts/get-package-builder-with-config.sh $cm $os $ac $version $profile
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for ac in $architectures; do
        for version in v0.5.0 v0.6.0; do
            echo "$cm $os $ac $version:"
            ./packages/scripts/get-package-builder-with-config.sh $cm $os $ac $version $profile
        done
    done
}

function test_gen_package_artifacts_script() {
    local versions="v7.5.0 v7.1.0 v6.5.0 v6.1.0"
    local components="tidb tiflow tiflash tikv pd ctl"
    local operating_systems="linux darwin"
    local architectures="amd64 arm64"
    local profile="release"

    for version in $versions; do
        for cm in $components; do
            for os in $operating_systems; do
                for ac in $architectures; do
                    echo "$cm $os $ac $version:"
                    ./packages/scripts/gen-package-artifacts-with-config.sh $cm $os $ac $version $profile branch-xxx 123456789abcdef
                done
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
            ./packages/scripts/gen-package-artifacts-with-config.sh $cm $os $ac $version $profile branch-xxx 123456789abcdef
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for ac in $architectures; do
        for version in v0.5.0 v0.6.0; do
            echo "$cm $os $ac $version:"
            ./packages/scripts/gen-package-artifacts-with-config.sh $cm $os $ac $version $profile branch-xxx 123456789abcdef
        done
    done
}

function test_gen_package_images_script() {
    local versions="v7.5.0 v7.1.0 v6.5.0 v6.1.0"
    local components="tidb tiflow tiflash tikv pd ctl"
    local architectures="amd64 arm64"
    local profile="release"

    for version in $versions; do
        for cm in $components; do
            for ac in $architectures; do
                echo "$cm $os $ac $version:"
                ./packages/scripts/gen-package-images-with-config.sh $cm linux $ac $version $profile branch-xxx 123456789abcdef
            done
        done
    done

    ##### others that owns theirs non-unified versions #####
    # tidb-operator
    local cm="tidb-operator"
    local os="linux"
    for ac in $architectures; do
        for version in v1.6.0 v1.5.0; do
            echo "$cm $os $ac $version:"
            ./packages/scripts/gen-package-images-with-config.sh $cm linux $ac $version $profile branch-xxx 123456789abcdef
        done
    done

    # advanced-statefulset
    local cm="advanced-statefulset"
    local os="linux"
    for version in v0.5.0 v0.6.0; do
        for ac in $architectures; do
            echo "$cm $os $ac $version:"
            ./packages/scripts/gen-package-images-with-config.sh $cm linux $ac $version $profile branch-xxx 123456789abcdef
        done
    done
}

function main() {
    test_get_builder
    test_gen_package_artifacts_script
    test_gen_package_images_script
}

main "$@"
