#!/bin/sh

validate() {
    validation=$(echo "$1" | grep -oE '^v?([0-9]+)\.([0-9]+)\.([0-9]+)$')
    if [ -z "$validation" ]
    then
        echo "Warning! Latest tag \"$1\" invalid format: expected vX.X.X or X.X.X"
        printf "Enter your next tag manually: "
        read -r manual_tag
        git_tag "$manual_tag"
        exit 0
    fi
}

select_menu() {
    while true
    do
        echo "1) $major - major"
        echo "2) $minor - minor"
        echo "3) $bugfix - bugfix"
        printf "Choose tag to apply: "
        read -r choice

        if [ "$choice" = "1" ]
        then
            tag=$major
            break
        fi
        if [ "$choice" = "2" ]
        then
            tag=$minor
            break
        fi
        if [ "$choice" = "3" ]
        then
            tag=$bugfix
            break
        fi
    done
}

ask_v_versioning() {
    echo "Latest tagged version: $tag"
    printf "Would you like to add a \"v\" prefix to your next version tag? (y/N) "
    read -r answer
    if [ "$answer" = "y" ]
    then
        v="v"
    fi
}

git_tag() {
    printf "Describe your tag: "
    read -r tag_description

    if [ "$tag_description" = "" ]
    then
        tag_description="$1"
    fi

    git tag -a "$1" -m "$tag_description" && echo "Done! Tag successfuly applied"
}

tag=$(git describe --abbrev=0 --tags 2>/dev/null || echo v0.0.0)
validate "$tag"

v=""
if [ "$(echo "$tag" | cut -c -1)" = "v" ]
then
    tag=$(echo "$tag" | cut -c2-)
    v="v"
else
    ask_v_versioning
fi

# The only way to be sh cross platform between MacOS, Linux...etc
# a.b.c represents a tag version e.g: "1.0.2"
remainder="$tag"
a="${remainder%%.*}"; remainder="${remainder#*.}"
b="${remainder%%.*}"; remainder="${remainder#*.}"
c="${remainder%%.*}"; remainder="${remainder#*.}"

major="$v$((a+1)).0.0"
minor="$v$a.$((b+1)).0"
bugfix="$v$a.$b.$((c+1))"

select_menu

git_tag "$tag"
