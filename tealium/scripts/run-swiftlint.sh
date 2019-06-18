#!/bin/sh

#  run-swiftlint.sh
#  tealium-swift
#
#  Created by Jonathan Wong on 2/5/18.
#  Copyright © 2018 Tealium, Inc. All rights reserved.

if which swiftlint > /dev/null; then
    cd ${PROJECT_DIR}/../tealium/ && swiftlint autocorrect --config ${PROJECT_DIR}/../.swiftlint.yml
    swiftlint lint --config ${PROJECT_DIR}/../.swiftlint.yml
else
    echo “warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint”
fi
