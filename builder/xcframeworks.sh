#!/bin/bash

#######################################################
# xcframework builder script for tealium-swift
#######################################################

# variable declarations
BUILD_PATH="build"
SURMAGIC_PATH="sm-frameworks"
XCFRAMEWORK_PATH="tealium-xcframeworks"
ZIP_PATH="tealium.xcframework.zip"


# zip all the xcframeworks
function zip_xcframeworks {
    if [[ -d "${XCFRAMEWORK_PATH}" ]]; then
        zip -r "${ZIP_PATH}" "${XCFRAMEWORK_PATH}"
        rm -rf "${XCFRAMEWORK_PATH}"
    fi
}

# do the work
surmagic xcf

mv "${SURMAGIC_PATH}" "${XCFRAMEWORK_PATH}"
zip_xcframeworks

mv "${ZIP_PATH}" "../"

echo ""
echo "Done! Upload ${ZIP_PATH} to GitHub when you create the release."
