#!/bin/bash

# Colors
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
ylw=$(tput setaf 3)             #  yellow
blu=$(tput setaf 4)             #  blue
ppl=$(tput setaf 5)             #  purple
cya=$(tput setaf 6)             #  cyan
txtbld=$(tput bold)             #  Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldylw=${txtbld}$(tput setaf 3) #  yellow
bldblu=${txtbld}$(tput setaf 4) #  blue
bldppl=${txtbld}$(tput setaf 5) #  purple
bldcya=${txtbld}$(tput setaf 6) #  cyan
txtrst=$(tput sgr0)             #  Reset
rev=$(tput rev)                 #  Reverse color
pplrev=${rev}$(tput setaf 5)
cyarev=${rev}$(tput setaf 6)
ylwrev=${rev}$(tput setaf 3)
blurev=${rev}$(tput setaf 4)

usage()
{
    echo ""
    echo ${txtbld}"Usage:"${txtrst}
    echo "  build.sh [options] device"
    echo ""
    echo ${txtbld}"  Options:"${txtrst}
    echo "    -c# Cleaning options before build:"
    echo "        1 - Run make clobber"
    echo "        2 - Run rm -rf out/target"
    echo "    -s  Sync source before build"
    echo ""
    echo ${txtbld}"  Example:"${txtrst}
    echo "    ./build.sh -c1 titan"
    echo ""
    exit 1
}

export KERNEL_TOOLCHAIN="`pwd`/prebuilt/linux-x86/toolchain/gcc-4.9.4/bin"
export USE_PREBUILT_CHROMIUM=1
export USE_CCACHE=1

opt_clean=0
opt_sync=0

while getopts "c:s" opt; do
    case "$opt" in
    c) opt_clean="$OPTARG" ;;
    s) opt_sync=1 ;;
    *) usage
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 1 ]; then
    usage
fi

if [ "$opt_sync" -eq 1 ]; then
    echo ${bldblu}"Fetching latest sources"${txtrst}
    repo sync buildscripts
    ./resync.sh
fi

if [ "$opt_clean" -eq 1 ]; then
    echo ${bldblu}"Running 'make clobber'"${txtrst}
    make clobber
elif [ "$opt_clean" -eq 2 ]; then
    echo ${bldblu}"Running 'rm -rf out/target'"${txtrst}
    rm -rf out/target
    echo
elif [ ! "$opt_clean" -eq 0 ]; then
    usage
fi

device="$1"

echo ${bldblu}"Setting up environment"${txtrst}
. build/envsetup.sh

echo ""
echo ${bldblu}"Lunching device"${txtrst}
breakfast $1

echo ${bldblu}"Starting compilation"${txtrst}
echo ""
LC_ALL=C mka bacon
