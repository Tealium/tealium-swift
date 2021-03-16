#!/bin/bash

# GET XCODE PROJECT (OR WORKSPACE) PATH, SCHEME, AND OUTPUT LOCATION
PROJECT="tealium-swift"
SCHEME="iOSTealiumTest"
OUTPUT_LOCATION="veracode"

# CLEAN OUTPUT FOLDER
rm -rf "$OUTPUT_LOCATION" 
mkdir "$OUTPUT_LOCATION"

xcodebuild archive \
	-project "tealium-swift.xcodeproj" \
	-scheme "iOSTealiumTest" \
	-archivePath "$PWD/tealium-swift.xcarchive" \
	-destination "generic/platform=iOS" \
	-allowProvisioningUpdates \
	DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
	ENABLE_BITCODE=YES

# MOVE APPLICATIONS DIRECTORY OUT OF PRODUCTS AND UP TO PARENT
cp -R Products/Applications Payload
rm -rf Products

# REMOVE THE PRODUCTS DIRECTORY
rm -rf ${PROJECT}.xcarchive/Products/

# ZIP ALL FILES IN XCODE ARCHIVE
cd ${PROJECT}.xcarchive
zip -r "../${OUTPUT_LOCATION}/${PROJECT}.bca" $(ls)

# REMOVE ARCHIVE
rm -rf "tealium-swift.xcarchive"

echo ""
echo "Package Created!"
