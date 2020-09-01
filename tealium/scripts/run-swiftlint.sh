#!/bin/sh

#  run-swiftlint-tests.sh
#  tealium-swift
#
#  Created by Jonathan Wong on 2/5/18.
#  Copyright © 2018 Tealium, Inc. All rights reserved.
if which swiftlint > /dev/null; then
# SwiftLint struggles to work with lists of files and maintain a reference to the config file, so this is a workaround.
# Xcode can pass in a list of files, but these have to be manually entered in the "input file list", which is prone to errors
# if someone forgets to add a new file.
pwd
FILE="${SCRIPT_INPUT_FILE_0}"
IFS=' '
read -ra file_array <<< $FILE

for i in $file_array
do
    swiftlint autocorrect --format --config ${PROJECT_DIR}/../.swiftlint.yml $i
    swiftlint lint --config ${PROJECT_DIR}/../.swiftlint.yml $i
done

FILE="${SCRIPT_INPUT_FILE_1}"
IFS=' '
read -ra file_array <<< $FILE

for i in $file_array
do
    swiftlint autocorrect --format --config ${PROJECT_DIR}/../.swiftlint.yml $i
    swiftlint lint --config ${PROJECT_DIR}/../.swiftlint.yml $i
done
else
echo “warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint”
fi
