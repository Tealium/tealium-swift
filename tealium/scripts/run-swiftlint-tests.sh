#!/bin/sh

#  run-swiftlint-tests.sh
#  tealium-swift
#
#  Created by Jonathan Wong on 2/5/18.
#  Copyright © 2018 Tealium, Inc. All rights reserved.
if which swiftlint > /dev/null; then
echo ${PROJECT_DIR}
echo $SRCROOT
cd $SRCROOT/../support/tests/ && swiftlint autocorrect --config ${PROJECT_DIR}/../.swiftlint-tests.yml
cd $SRCROOT/
swiftlint lint --config ${PROJECT_DIR}/../.swiftlint_tests.yml
else
echo “warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint”
fi
