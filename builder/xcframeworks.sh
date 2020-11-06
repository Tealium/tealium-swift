#!/bin/bash

#######################################################
# xcframework builder script for tealium-swift
#######################################################

# variable declarations
BUILD_PATH="build"
XCFRAMEWORK_PATH="tealium-xcframeworks"
XCODE_PROJECT="tealium-swift"
MACOS_SDKROOT="SDKROOT = macosx;"
IOS_SDKROOT="SDKROOT = \"iphoneos\";"
LATEST_MAJOR="2."
PREVIOUS_MAJOR="1."
IOS_ONLY_PRODUCTS="TealiumAttributionTealiumAutotrackingTealiumLocationTealiumCrashTealiumRemoteCommandsTealiumTagManagement"
declare -a PRODUCT_NAME
# destinations
IOS_SIM_DESTINATION="generic/platform=iOS Simulator"
IOS_DESTINATION="generic/platform=iOS"
TVOS_SIM_DESTINATION="generic/platform=tvOS Simulator"
TVOS_DESTINATION="generic/platform=tvOS"
WATCHOS_SIM_DESTINATION="generic/platform=watchOS Simulator"
WATCHOS_DESTINATION="generic/platform=watchOS"
MACOS_DESTINATION="generic/platform=macOS"
CATALYST_DESTINATION="platform=macOS,variant=Mac Catalyst"
# xcarchives
IOS_SIM_ARCHIVE="ios-sim.xcarchive"
IOS_ARCHIVE="ios.xcarchive"
TVOS_SIM_ARCHIVE="tvos-sim.xcarchive"
TVOS_ARCHIVE="tvos.xcarchive"
WATCHOS_SIM_ARCHIVE="watchos-sim.xcarchive"
WATCHOS_ARCHIVE="watchos.xcarchive"
MACOS_ARCHIVE="macos.xcarchive"
CATALYST_ARCHIVE="ios-catalyst.xcarchive"

# function declarations
function define_product_name {
    case $1 in
        *"$LATEST_MAJOR"*)
            PRODUCT_NAME=(TealiumCore TealiumAttribution TealiumAutotracking TealiumCollect TealiumLifecycle TealiumLocation TealiumRemoteCommands TealiumTagManagement TealiumVisitorService)
            ;;
        *"$PREVIOUS_MAJOR"*)
            PRODUCT_NAME=(TealiumCore TealiumAppData TealiumAttribution TealiumAutotracking TealiumCollect TealiumConsentManager TealiumCrash TealiumDelegate TealiumDeviceData TealiumDispatchQueue TealiumLifecycle TealiumLocation TealiumLogger TealiumPersistentData TealiumRemoteCommands TealiumTagManagement TealiumVisitorService TealiumVolatileData)
            ;;
        *)
            echo "ERROR, VERSION NUMBER INVALID"
            ;;
    esac    
}

function clean_build_folder {
    if [[ -d "${BUILD_PATH}" ]]; then
        rm -rf "${BUILD_PATH}"
    fi
    if [[ -d "${XCFRAMEWORK_PATH}" ]]; then
        rm -rf "${XCFRAMEWORK_PATH}"
    fi
    if [[ -d "${XCFRAMEWORK_PATH}.zip" ]]; then
        rm "${XCFRAMEWORK_PATH}.zip"
    fi
    mkdir "${XCFRAMEWORK_PATH}"
}

function check_architecture {
    local archs=( "$@" )
    for arch in "${archs[@]}"
    do 
        if ! echo "$1" | grep -q "${arch}"; then
            echo "ERROR, ARCHITECTURE MISSING!!!"
        else              # uncomment for debugging
            echo "+found ${arch}"
        fi
    done
}

# create indv archive
function archive {
    xcodebuild archive \
    -project "${XCODE_PROJECT}.xcodeproj" \
    -scheme "${1}" \
    -destination "${2}" \
    -archivePath "${3}" \
    -sdk "${4}" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SUPPORTS_MACCATALYST=YES \
    BUILD_SCRIPT=YES
    echo "Archiving ${1} ${2} ${3} ${4}"   
}

# create xcframeworks for ios only products
function create_xcframework_ios_only {
        xcodebuild -create-xcframework \
        -framework "${BUILD_PATH}/${IOS_SIM_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
        -framework "${BUILD_PATH}/${IOS_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
        -framework "${BUILD_PATH}/${CATALYST_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
        -output "${XCFRAMEWORK_PATH}/${1}".xcframework;
}

# create xcframeworks for products supporting all platforms
function create_xcframework_all {
    xcodebuild -create-xcframework \
    -framework "${BUILD_PATH}/${IOS_SIM_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
    -framework "${BUILD_PATH}/${IOS_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
    -framework "${BUILD_PATH}/${TVOS_SIM_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
    -framework "${BUILD_PATH}/${TVOS_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
    -framework "${BUILD_PATH}/${WATCHOS_SIM_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
    -framework "${BUILD_PATH}/${WATCHOS_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
    -framework "${BUILD_PATH}/${MACOS_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
    -framework "${BUILD_PATH}/${CATALYST_ARCHIVE}/Products/Library/Frameworks/${1}.framework" \
    -output "${XCFRAMEWORK_PATH}/${1}".xcframework;
}

# create xcframework for each product that contains all supported platforms
function create_xcframework {   
    if [[ "$IOS_ONLY_PRODUCTS" == *"$1"* ]]; then
        create_xcframework_ios_only "${1}"   
    else
        create_xcframework_all "${1}"
    fi
}

# create archives for ios only products
function create_archives_ios_only {
    archive "$1" "${IOS_SIM_DESTINATION}" "${BUILD_PATH}/${IOS_SIM_ARCHIVE}" "iphonesimulator"
    archive "$1" "${IOS_DESTINATION}" "${BUILD_PATH}/${IOS_ARCHIVE}" "iphoneos";
    archive "$1" "${CATALYST_DESTINATION}" "${BUILD_PATH}/${CATALYST_ARCHIVE}" "iphoneos";
    create_xcframework "$1"
}

# create archives for products supporting all platforms
function create_archives_all {
    archive "$1" "${IOS_SIM_DESTINATION}" "${BUILD_PATH}/${IOS_SIM_ARCHIVE}" "iphonesimulator"
    archive "$1" "${IOS_DESTINATION}" "${BUILD_PATH}/${IOS_ARCHIVE}" "iphoneos"
    archive "$1" "${TVOS_SIM_DESTINATION}" "${BUILD_PATH}/${TVOS_SIM_ARCHIVE}" "appletvsimulator"
    archive "$1" "${TVOS_DESTINATION}" "${BUILD_PATH}/${TVOS_ARCHIVE}" "appletvos"
    archive "$1" "${WATCHOS_SIM_DESTINATION}" "${BUILD_PATH}/${WATCHOS_SIM_ARCHIVE}" "watchsimulator"
    archive "$1" "${WATCHOS_DESTINATION}" "${BUILD_PATH}/${WATCHOS_ARCHIVE}" "watchos"
    archive "$1" "${MACOS_DESTINATION}" "${BUILD_PATH}/${MACOS_ARCHIVE}" "macosx"
    archive "$1" "${CATALYST_DESTINATION}" "${BUILD_PATH}/${CATALYST_ARCHIVE}" "iphoneos";
    create_xcframework "$1" 
}

# create all archives for each product and platform
function create_archives {
    if [ -z "$1" ]
      then
        echo "WARNING, NO VERSION NUMBER ENTERED. ASSUMING LATEST."
        define_product_name "${LATEST_MAJOR}"
    else
        define_product_name "$1"
    fi
    for i in "${PRODUCT_NAME[@]}"; 
        do
            if [[ "$IOS_ONLY_PRODUCTS" == *"$i"* ]]; then                
                create_archives_ios_only "$i"
            else
                create_archives_all "$i" 
            fi    
        done    
}

# zip all the xcframeworks
function zip_xcframeworks {
    if [[ -d "${XCFRAMEWORK_PATH}" ]]; then
        zip -r "${XCFRAMEWORK_PATH}.zip" "${XCFRAMEWORK_PATH}"
        rm -rf "${XCFRAMEWORK_PATH}"
    fi
}

#### start ####
clean_build_folder

# do the work
create_archives "$1"
zip_xcframeworks

echo ""
echo "Done! Upload ${XCFRAMEWORK_PATH}.zip to GitHub when you create the release."