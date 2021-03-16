#!/bin/bash

# GET XCODE PROJECT (OR WORKSPACE) PATH, SCHEME, AND OUTPUT LOCATION
PROJECT="tealium-swift"
SCHEME="iOSTealiumTest"
OUTPUT_LOCATION="veracode"

# CLEAN OUTPUT FOLDER
rm -rf "$OUTPUT_LOCATION" 
mkdir "$OUTPUT_LOCATION"

xcodebuild archive \
	-project "${PROJECT}.xcodeproj" \
	-scheme $SCHEME \
	-archivePath "$PWD/${PROJECT}.xcarchive" \
	-destination "generic/platform=iOS" \
	-allowProvisioningUpdates \
	DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
	ENABLE_BITCODE=YES

cd ${PROJECT}.xcarchive

# MOVE APPLICATIONS DIRECTORY OUT OF PRODUCTS AND UP TO PARENT
cp -R Products/Applications Payload
rm -rf Products

# REMOVE THE PRODUCTS DIRECTORY
rm -rf ${PROJECT}.xcarchive/Products/

# ZIP ALL FILES IN XCODE ARCHIVE
zip -r "../${OUTPUT_LOCATION}/${PROJECT}.bca" $(ls)

cd ..

# REMOVE ARCHIVE
rm -rf "${PROJECT}.xcarchive"

echo ""
echo "Package ${PROJECT}.bca created!"
