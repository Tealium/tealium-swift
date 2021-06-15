#!/bin/bash

# GET XCODE PROJECT (OR WORKSPACE) PATH, SCHEME, AND OUTPUT LOCATION
PROJECT="tealium-swift"
SCHEME="iOSTealiumTest"

# CREATE THE ARCHIVE
xcodebuild archive \
	-project "${PROJECT}.xcodeproj" \
	-scheme $SCHEME \
	-archivePath "$PWD/${PROJECT}.xcarchive" \
	-destination "generic/platform=iOS" \
	-allowProvisioningUpdates \
	DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
	ENABLE_BITCODE=YES

# ZIP ALL FILES IN XCODE ARCHIVE
zip -r "${PROJECT}.zip" "${PROJECT}.xcarchive"

# REMOVE ARCHIVE & ZIP
rm -rf "${PROJECT}.xcarchive"

echo ""
echo "Package ${PROJECT}.zip created!"
