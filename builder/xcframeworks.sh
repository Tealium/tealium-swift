#!/bin/bash

#######################################################
# xcframework builder script for tealium-swift
#######################################################

# variable declarations
BUILD_PATH="build"
XCFRAMEWORK_PATH="tealium-xcframeworks"
ZIP_PATH="tealium.xcframework.zip"
TEAM_NAME=XC939GDC9P

# zip all the xcframeworks
function zip_xcframeworks {
    if [[ -d "${XCFRAMEWORK_PATH}" ]]; then
        ditto -ck --rsrc --sequesterRsrc --keepParent "${XCFRAMEWORK_PATH}" "${ZIP_PATH}" 
        rm -rf "${XCFRAMEWORK_PATH}"
    fi
}

# do the work
surmagic xcf

# Code Sign
for frameworkname in $XCFRAMEWORK_PATH/*.xcframework; do
    echo "Codesigning $frameworkname"
    codesign --timestamp -s $TEAM_NAME $frameworkname --verbose
    codesign -v $frameworkname --verbose
done

zip_xcframeworks

mv "${ZIP_PATH}" "../"

echo ""
echo "Done! Upload ${ZIP_PATH} to GitHub when you create the release."
