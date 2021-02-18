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
	-archivePath "tealium-swift.xcodeproj" \
	-destination "generic/platform=iOS" \
	DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
	ENABLE_BITCODE=YES

# MOVE APPLICATIONS DIRECTORY OUT OF PRODUCTS AND UP TO PARENT
mv ${PROJECT}.xcarchive/Products/Applications/ ${PROJECT}.xcarchive/Payload/

# REMOVE THE PRODUCTS DIRECTORY
rmdir ${PROJECT}.xcarchive/Products/

# ZIP ALL FILES IN XCODE ARCHIVE
cd ${PROJECT}.xcarchive
zip -r ${OUTPUT_LOCATION}/${PROJECT}.bca $(ls)

# REMOVE ARCHIVE
rm -rf "tealium-swift.xcodeproj.xcarchive"

echo ""
echo "Directory listing: "
ls