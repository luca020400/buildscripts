root="$PWD"
patch_list=(
    'build chromium_build.patch 4.8_build.patch'
    'external/bash 4.8_external_bash.patch'
    'vendor/cm chromium_vendor_cm.patch'
    'frameworks/webview chromium_frameworks_webview.patch'
)

function patch {
    count=0

    while [ "x${patch_list[count]}" != "x" ]; do
        curr="${patch_list[count]}"
        patches=`echo "$curr" | cut -d " " -f2-`
        folder=`echo "$curr" | awk '{print $1}'`

        cd "$folder"

        if [ "$1" = "apply" ]; then
            for patch in $patches; do
                git am "$root/patches/$patch"
            done
        elif [ "$1" = "reset" ]; then
            git reset --hard github/cm-11.0
        fi

        cd "$root"

        count=$(( $count + 1 ))
    done
}

patch reset

repo sync -f -j12
vendor/cm/get-prebuilts

patch apply
