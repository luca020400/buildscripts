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
export USE_CCACHE=1

# CM Version
export CM_VERSION_MAJOR="13"
export CM_VERSION_MINOR="0"
export CM_VERSION_MAINTENANCE="Unofficial"

usage()
{
    echo
    echo -e ${bldblu}"Usage:"${bldcya}
    echo -e "  build.sh [options] device"
    echo
    echo -e ${bldblu}"  Options:"${bldcya}
    echo -e "    -c# Cleaning options before build:"
    echo -e "        1 - Run make clobber"
    echo -e "        2 - Run rm -rf out/target"
    echo -e "    -o# Only build:"
    echo -e "        1 - Boot Image"
    echo -e "        2 - Recovery Image"
    echo -e "    -s  Sync source before build"
    echo
    echo -e ${bldblu}"  Example:"${bldcya}
    echo -e "    ./build.sh -c1 thea"
    echo -e "${rst}"
    exit 1
}

# Job calculation
if uname -a | grep Darwin; then
    jobs=$(sysctl hw.ncpu | awk '{print $2}')
else
    jobs=$(grep "^processor" /proc/cpuinfo -c)
fi

opt_clean=0
opt_target=0
opt_sync=0

while getopts "c:o:s" opt; do
    case "$opt" in
    c) opt_clean="$OPTARG" ;;
    o) opt_target="$OPTARG" ;;
    s) opt_sync=1 ;;
    *) usage ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 1 ]; then
    usage
fi

device="$1"

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

# Sync
if [ "$opt_sync" -eq 1 ]; then
    echo -e "${bldcya}Fetching latest sources${rst}"
    repo sync buildscripts
    repo sync -f --force-sync -j5
    echo
fi

# Setup environment
echo -e "${bldcya}Setting up environment${rst}"
echo -e "${bldmag}${line}${rst}"
. build/envsetup.sh
echo -e "${bldmag}${line}${rst}"
echo

# Lunch device
echo -e "${bldcya}Lunching device${rst}"
breakfast "$device"

# Start compilation
if [ "$opt_target" -eq 1 ]; then
    echo -e "${bldcya}Starting compilation: ${bldgrn}Building Boot Image only${rst}"
    echo
    LC_ALL=C ionice -c2 -n1 make $opt_jobs bootimage
elif [ "$opt_target" -eq 2 ]; then
    echo -e "${bldcya}Starting compilation: ${bldgrn}Building Recovery Image only${rst}"
    echo
    LC_ALL=C ionice -c2 -n1 make $opt_jobs recoveryimage
else
    echo -e "${bldcya}Starting compilation: ${bldgrn}Building ${bldylw}CyanogenMod ${bldmag}$CM_VERSION_MAJOR${bldcya}$CM_VERSION_MINOR ${bldred}$CM_VERSION_MAINTENANCE${rst}"
    echo
    LC_ALL=C ionice -c2 -n1 make $opt_jobs bacon
fi
