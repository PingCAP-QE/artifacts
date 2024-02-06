#!/usr/bin/env bash
set -euo pipefail

RELEASE_SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT_DIR=$(realpath "${RELEASE_SCRIPTS_DIR}/../..")

# Function to copy container image to destination repositories based on rules defined in YAML config
main() {
    local image_url_with_tag="$1"
    local yaml_file="${2:-${PROJECT_ROOT_DIR}/packages/delivery.yaml}"
    local out_file="${3:-${RELEASE_SCRIPTS_DIR}/delivery-images.sh}"
    rm -rf $out_file

    # Extract image URL and tag
    local image_url=$(echo "$image_url_with_tag" | cut -d ':' -f1)
    local tag=$(echo "$image_url_with_tag" | cut -d ':' -f2)

    # Retrieve rules for the source repository from the YAML config
    local rules=$(yq ".image_copy_rules[\"$image_url\"]" "$yaml_file")
    local rule_count=$(yq ".image_copy_rules[\"$image_url\"] | length" "$yaml_file")
    if [ $rule_count -eq 0 ]; then
        echo "🤷 none rules found for image: $image_url"
        exit 0
    fi

    # Loop through each rule for the source repository
    for ri in $(seq 0 $((rule_count - 1))); do
        echo $ri
        local rule=$(yq ".image_copy_rules[\"$image_url\"][$ri]" "$yaml_file")
        description=$(yq '.description' <<< "$rule")
        dest_repos=$(yq '.dest_repositories[]' <<< "$rule")
        dest_tags=

        # Check if the tag matches the tags regex
        if yq -e ".tags_regex[] | select(. | test \"$tag\")" 2>&1> /dev/null <<< "$rule" ; then
            echo "Matching rule found for image URL '$image_url_with_tag':"
            echo "  Description: $description"
            echo "  Source Repository: $image_url"

            # Copy image to destination repositories using crane copy command
            for dest_repo in $dest_repos; do
                echo "  Destination Repository: $dest_repo"
                echo "crane copy $image_url_with_tag $dest_repo:$tag" >> "$out_file"
                for constant_tag in $(yq '.constant_tags[]' <<< "$rule"); do
                    echo "crane tag $dest_repo:$tag $constant_tag" >> "$out_file"
                done
            done
        fi
    done

    if [ -f "$out_file" ]; then
        echo "✅ Generated shell script: $out_file"
    fi
}

main "$@"
