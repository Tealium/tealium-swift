#!/bin/bash

# A script to verify that the repo is up to date and the versions are correct and then runs the pod trunk push command

constants=$(<tealium/core/TealiumConstants.swift)
regex="^.*public static let libraryVersion \= \"([0-9\.]*)\""

if [[ $constants =~ $regex ]]
then
    versionConstant=${BASH_REMATCH[1]}
else
    echo "Couldn't match the library version, exiting"
    exit 1
fi
echo Version Constant "$versionConstant"

podspecFile=$(<tealium-swift.podspec)
podspecRegex="^.*s.version[[:space:]]*\= \"([0-9\.]*)\""

if [[ $podspecFile =~ $podspecRegex ]]
then
    podspecVersion=${BASH_REMATCH[1]}
else
    echo "Couldn't match the podspec version, exiting"
    exit 1
fi
echo Podspec Version  "$podspecVersion"

if [ "$podspecVersion" != "$versionConstant" ]
then
  printf "The podspec version \"%s\" is different from the version constant \"%s\".\nDid you forget to update one of the two?\n" "$podspecVersion" "$versionConstant"
  exit 1
fi

branch_name="$(git rev-parse --abbrev-ref HEAD)"
echo Current branch "$branch_name"
if [ "$branch_name" != "main" ]
then 
  echo "Check out to main branch before trying to publish. Current branch: ${branch_name}"
  exit 1
fi

git fetch --tags
if ! git diff --quiet remotes/origin/main
then
  echo "Make sure you are up to date with the remote before publishing"
  exit 1
fi

latestTag=$(git describe --tags --abbrev=0)

echo Latest tag "$latestTag"
if [ "$latestTag" != "$versionConstant" ]
then
  printf "The latest published tag \"%s\" is different from the version constant \"%s\".\nDid you forget to add the tag to the release or did you forget to update the Constant?" "$latestTag" "$versionConstant"
  exit 1
fi



echo "All checks are passed, ready to release to CocoaPods"

echo "Do you wish to publish to CocoaPods?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo "Ok, running \"pod trunk push\" now."; pod trunk push; break;;
        No ) echo "Ok, skip the release for now."; exit;;
    esac
done

