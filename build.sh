#!/bin/bash

# Colors
esc="\033"
bld="${esc}[1m"            #  Bold
rst="${esc}[0m"            #  Reset

bla="${esc}[30m"           #  Black          - Text
red="${esc}[31m"           #  Red            - Text
grn="${esc}[32m"           #  Green          - Text
ylw="${esc}[33m"           #  Yellow         - Text
blu="${esc}[34m"           #  Blue           - Text
mag="${esc}[35m"           #  Magenta        - Text
cya="${esc}[36m"           #  Cyan           - Text
whi="${esc}[37m"           #  Light Grey     - Text

bldbla=${bld}${bla}        #  Dark Grey      - Text
bldred=${bld}${red}        #  Red            - Bold Text
bldgrn=${bld}${grn}        #  Green          - Bold Text
bldylw=${bld}${ylw}        #  Yellow         - Bold Text
bldblu=${bld}${blu}        #  Blue           - Bold Text
bldmag=${bld}${mag}        #  Magenta        - Bold Text
bldcya=${bld}${cya}        #  Cyan           - Bold Text
bldwhi=${bld}${whi}        #  White          - Text

bgbla="${esc}[40m"         #  Black          - Background
bgred="${esc}[41m"         #  Red            - Background
bggrn="${esc}[42m"         #  Green          - Background
bgylw="${esc}[43m"         #  Yellow         - Background
bgblu="${esc}[44m"         #  Blue           - Background
bgmag="${esc}[45m"         #  Magenta        - Background
bgcya="${esc}[46m"         #  Cyan           - Background
bgwhi="${esc}[47m"         #  Light Grey     - Background

bldbgbla=${bld}${bgbla}    #  Dark Grey      - Background
bldbgred=${bld}${bgred}    #  Red            - Bold Background
bldbggrn=${bld}${bggrn}    #  Green          - Bold Background
bldbgylw=${bld}${bgylw}    #  Yellow         - Bold Background
bldbgblu=${bld}${bgblu}    #  Blue           - Bold Background
bldbgmag=${bld}${bgmag}    #  Magenta        - Bold Background
bldbgcya=${bld}${bgcya}    #  Cyan           - Bold Background
bldbgwhi=${bld}${bgwhi}    #  White          - Background

# User Defined variables
export KERNEL_TOOLCHAIN="`pwd`/prebuilt/linux-x86/toolchain/gcc-4.9.4/bin"
export USE_PREBUILT_CHROMIUM=1
export USE_CCACHE=1

# CM Version
export CM_VERSION_MAJOR="12"
export CM_VERSION_MINOR=".1"
export CM_VERSION_MAINTENANCE="Unofficial"

usage()
{
    echo ""
    echo -e ${bldblu}"Usage:"${bldcya}
    echo -e "  build.sh [options] device"
    echo ""
    echo -e ${bldblu}"  Options:"${bldcya}
    echo -e "    -a  Disable ADB authentication and set root access to Apps and ADB"
    echo -e "    -c# Cleaning options before build:"
    echo -e "        1 - Run make clobber"
    echo -e "        2 - Run rm -rf out/target"
    echo -e "    -e# Extra build output options:"
    echo -e "        1 - Verbose build output"
    echo -e "        2 - Quiet build output"
    echo -e "    -j# Set number of jobs"
    echo -e "    -o# Only build:"
    echo -e "        1 - Boot Image"
    echo -e "        2 - Recovery Image"
    echo -e "    -s  Sync source before build"
    echo ""
    echo -e ${bldblu}"  Example:"${bldcya}
    echo -e "    ./build.sh -c1 thea"
    echo -e "${rst}"
    exit 1
}

# Get OS (Linux / Mac OS X)
IS_DARWIN=$(uname -a | grep Darwin)
if [ -n "$IS_DARWIN" ]; then
    CPUS=$(sysctl hw.ncpu | awk '{print $2}')
else
    CPUS=$(grep "^processor" /proc/cpuinfo -c)
fi

opt_adb=0
opt_clean=0
opt_extra=0
opt_jobs="$CPUS"
opt_only=0
opt_sync=0

while getopts "ac:e:j:o:s" opt; do
    case "$opt" in
    a) opt_adb=1 ;;
    c) opt_clean="$OPTARG" ;;
    e) opt_extra="$OPTARG" ;;
    j) opt_jobs="$OPTARG" ;;
    o) opt_only="$OPTARG" ;;
    s) opt_sync=1 ;;
    *) usage ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 1 ]; then
    usage
fi
device="$1"

# Disable ADB authentication
if [ "$opt_adb" -ne 0 ]; then
    echo -e "${bldcya}Disabling ADB authentication and setting root access to Apps and ADB${rst}"
    export DISABLE_ADB_AUTH=true
    echo ""
else
    unset DISABLE_ADB_AUTH
fi

# Clean
if [ "$opt_clean" -eq 1 ]; then
    echo -e "${bldblu}Running 'make clobber'${rst}"
    make clobber
elif [ "$opt_clean" -eq 2 ]; then
    echo -e "${bldblu}Running 'rm -rf out/target'${rst}"
    rm -rf out/target
    echo
elif [ ! "$opt_clean" -eq 0 ]; then
    usage
fi

# Get extra options for build
if [ "$opt_extra" -eq 1 ]; then
    opt_v=" "showcommands
elif [ "$opt_extra" -eq 2 ]; then
    opt_v=" "-s
else
    opt_v=""
fi

# Check if jobs is a valid number
if [ $opt_jobs -eq $opt_jobs ]; then
    opt_jobs="-j$opt_jobs"
else
    opt_jobs="-j$CPUS"
fi

# Sync
if [ "$opt_sync" -eq 1 ]; then
    echo -e "${bldcya}Fetching latest sources${rst}"
    repo sync buildscripts
    ./resync.sh
    echo ""
fi

# Check directories
if [ ! -d ".repo" ]; then
    echo -e "${bldred}No .repo directory found.  Is this an Android build tree?${rst}"
    echo ""
    exit 1
elif [ ! -d "vendor/cm" ]; then
    echo -e "${bldred}No vendor/cm directory found.  Is this a CM build tree?${rst}"
    echo ""
    exit 1
fi

device="$1"

# Setup environment
echo -e "${bldcya}Setting up environment${rst}"
echo -e "${bldmag}${line}${rst}"
. build/envsetup.sh
echo -e "${bldmag}${line}${rst}"

# Lunch device
echo ""
echo -e "${bldcya}Lunching device${rst}"
breakfast "cm_$device-userdebug"

# Start compilation
if [ "$opt_only" -eq 1 ]; then
    echo -e "${bldcya}Starting compilation: ${bldgrn}Building Boot Image only${rst}"
    echo ""
    LC_ALL=C make $opt_jobs$opt_v bootimage
elif [ "$opt_only" -eq 2 ]; then
    echo -e "${bldcya}Starting compilation: ${bldgrn}Building Recovery Image only${rst}"
    echo ""
    LC_ALL=C make $opt_jobs$opt_v recoveryimage
else
    echo -e "${bldcya}Starting compilation: ${bldgrn}Building ${bldylw}CyanogenMod ${bldmag}$CM_VERSION_MAJOR${bldcya}$CM_VERSION_MINOR ${bldred}$CM_VERSION_MAINTENANCE${rst}"
    echo ""
    LC_ALL=C make $opt_jobs$opt_v bacon
fi
