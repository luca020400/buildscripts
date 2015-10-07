#!/bin/bash

root="$PWD"
patch_list=(
    'build chromium_build.patch'
    'vendor/cm chromium_vendor_cm.patch'
)

function patch {
    local count=0

    while [ "x${patch_list[count]}" != "x" ]; do
        curr="${patch_list[count]}"
        patches=`echo "$curr" | cut -d " " -f2-`
        folder=`echo "$curr" | awk '{print $1}'`

        cd "$folder"

        if [ "$1" = "apply" ]; then
            for patch in $patches; do
                git am "$root/buildscripts/patches/$patch"
            done
        elif [ "$1" = "reset" ]; then
            git reset --hard github/cm-13.0
        fi

        cd "$root"

        count=$(( $count + 1 ))
    done
}

patch reset

repo sync -f -j4

patch apply
