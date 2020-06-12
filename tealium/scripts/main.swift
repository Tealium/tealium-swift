#!/usr/bin/env swiftshell
//  main.swift
//  swift-release
//
//  Created by Christina S on 2/3/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import SwiftShell


// TODO: Create addt'l script that will run all unit tests (started, need to finish)
// TODO: Prompt to push branch
// TODO: If they want to push, prompt to create PR
// TODO: Create PR w/github api
// TODO: Include sample apps scripts to update podfile version


var version: String? = nil
var newModuleName: String? = nil
var versionExists = false
var cleanctx = CustomContext(main)
let cleanenvvars = ["TERM_PROGRAM", "SHELL", "TERM", "TMPDIR", "Apple_PubSub_Socket_Render", "TERM_PROGRAM_VERSION", "TERM_SESSION_ID", "USER", "SSH_AUTH_SOCK", "__CF_USER_TEXT_ENCODING", "XPC_FLAGS", "XPC_SERVICE_NAME", "SHLVL", "HOME", "LOGNAME", "LC_CTYPE", "_"]
cleanctx.env = cleanctx.env.filterToDictionary(keys: cleanenvvars)
cleanctx.env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
var result = cleanctx.run(bash: "brew install xcodegen")
var publicRepoPath: String?
var builderRepoPath: String?
var greeting: String {
    result = cleanctx.run(bash: "brew install python3")
    return """
    ************************* Tealium Builder Release Script ************************\n
    *********************************************************************************
             👩🏻‍💻 Make sure you do not have the tealium-swift project open! 👨‍💻
    \n
    """
}

func getRepoPaths() {
    print("What is the full path to your builder repo? Please include trailing slash e.g. /Users/<username>/enter/full/path/tealium-swift-builder/")
    while let path = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
        var mutablePath = path
        mutablePath.removeAll(where: { [""].contains($0) })
        mutablePath.append("/")
        result = cleanctx.run(bash: "cd \(mutablePath)")
        guard result.stderror == "" else {
            print("Please enter a valid path")
            exit(1)
        }
        builderRepoPath = mutablePath
        publicRepoPath = builderRepoPath?.replacingOccurrences(of: "-builder", with: "")
        break
    }
}

func greetAndSetDirectories() {
    print(greeting)
    cleanctx.currentdirectory = publicRepoPath ?? ""
}


func checkVersion() {
    print("Please provide a version number to release: ")
    while let input = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
        guard input.split(separator: ".").map({ Int($0) }).count == 3 else {
            print("Format of version must be X.X.X i.e. 1.9.5 or 2.4.1 etc")
            exit(1)
        }
        result = cleanctx.run(bash: "git branch")
        version = input
        if result.stdout.contains(input) {
            print("Version already exists, skipping version update")
            // skip until checking `nothing to commit step`
            versionExists = true
            break
        }
        print("updating to version number \(version!)")
        break
    }
}

func checkForNewModules(_ version: String) {
    cleanctx.currentdirectory = builderRepoPath ?? ""
    print("Do you need to add any new modules in this version? y/n")
    while let input = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
        if input.lowercased() == "y" || input.lowercased() == "yes" {
            print("Please enter the module name (format = TealiumNewModule): ")
            while let newModule = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
                guard newModule.hasPrefix("Tealium") else {
                    print("The module name must be prefixed with `Tealium`")
                    exit(1)
                }
                newModuleName = newModule

                break
            }
            let shortModuleName = newModuleName?.replacingOccurrences(of: "Tealium", with: "").lowercased()
            print("Do you want to exclude any platforms from this module? y/n")
            while let shouldExclude = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
                if shouldExclude == "y" || input.lowercased() == "yes" {
                    cleanctx.run(bash: "chmod +x new-module.py")
                    print("List your excluded platforms in a comma separated string e.g. tvos,osx")
                    while let excluded = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
                        guard excluded.split(separator: ",")
                            .filter({ $0 != "tvos" && $0 != "osx" && $0 != "ios" && $0 != "watchos" }).isEmpty else {
                                print("""
                                The excluded platforms must be either of the following: tvos, ios, osx or watchos.
                                Separated by a comma with no whitespace.
                                """)
                                exit(1)
                        }
                        cleanctx.run(bash: "python3 ./new-module.py -v \(version) -f \(newModuleName!) -s \(shortModuleName!) -e \(excluded.lowercased())")
                        break
                    }
                } else {
                    cleanctx.run(bash: "python3 ./new-module.py -v \(version) -f \(newModuleName!) -s \(shortModuleName!)")
                }
                break
            }
        } else {
            cleanctx.run(bash: "python3 ./new-module.py -v \(version)")
        }
        break
    }
}

func checkForChanges() {
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "git fetch")
    result = cleanctx.run(bash: "git status")
    if !result.stdout.contains("nothing to commit")  {
        print("There are unstaged changes, please commit or stash")
        // provide options - 1 to stash 2
        print("1 - stash changes")
        print("2 - commit changes")
        while let input = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
            if input == "1" {
                cleanctx.run(bash: "git stash save -u saved-by-swift-release-script-\(Date())")
                cleanctx.run(bash: "git clean -d -f")
                break
            } else if input == "2" {
                print("Enter commit msg: ")
                while let commitMsg = main.stdin.readSome() {
                    cleanctx.run(bash: "git add --all")
                    cleanctx.run(bash: "git commit -m \(commitMsg)")
                    break
                }
                break
            }
        }
    }
}

func checkIfBranchAlreadyExists(_ version: String) {
    cleanctx.currentdirectory = publicRepoPath ?? ""
    if versionExists {
        cleanctx.run(bash: "git checkout \(version)")
    } else {
        cleanctx.run(bash: "git checkout -b \(version)")
    }

}

func copyPodspec(_ version: String) {
    // Copy podspec over to public repo
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "rsync -arv \(builderRepoPath ?? "")/tealium-swift.podspec ./")
    print("podspec copied")
}

func copyPackage() {
    // Copy Package.swift over to public repo
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "rsync -arv \(builderRepoPath ?? "")/Package.swift ./")
    print("Package.swift copied")
}

func copySourceFiles() {
    // Copy tealium folder over to public repo
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "rsync -arv \(builderRepoPath ?? "")/tealium ./")
    print("Tealium folder copied")

    // Copy unit tests folder over to public repo
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "rsync -arv \(builderRepoPath ?? "")/support ./")
    print("Support (unit tests) folder copied")
}

// TODO: Make consolidated unit test targets for iOS, macOS, and tvOS
// This currently takes too long with all the test schemes/targets
func runTests() {
    cleanctx.currentdirectory = "\(builderRepoPath ?? "")/builder"
    cleanctx.run(bash: "chmod +x unit-tests.sh")
    let tests = cleanctx.runAsync(bash: "./unit-tests.sh > ~/Desktop/testoutput.txt").onCompletion { command in
        if let readfile = try? open("~/Desktop/testoutput.txt") {
            let contents = readfile.read()
            let numberOfFailures = contents.components(separatedBy: "failed")
            print("There were \(numberOfFailures.count - 1) failures in the unit tests. Please fix the failing tests and/or update the code, then come back and try again 😁")
        }
    }
    _ = try? tests.finish()
}

func generateNewProject() {
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "cp \(builderRepoPath ?? "")/project.yml ./")
    result = cleanctx.run(bash: "xcodegen generate -p ./builder")
    cleanctx.run(bash: "rm ./project.yml")
    print("New project generated")
}


func removeUneccessaryFiles() {
    cleanctx.run(bash: "rm -rf ./builder/TealiumCrash && rm -rf ./builder/TealiumSwift && rm -rf ./builder/docs && rm ./builder/README.md")
    print("Extra folders/files removed")
}

func commitAndPushToBuilder(_ version: String) {
    // Committing version (podspec), module (package.swift), and formatting (swiftlint) changes to builder
    cleanctx.currentdirectory = builderRepoPath ?? ""
    cleanctx.run(bash: "git checkout -b release-script/\(version)-cleanup")
    cleanctx.run(bash: "git add --all")
    cleanctx.run(bash: "git commit -m \"Updated .podspec (possibly Package.swift) and formatteed using swfitlint for version \(version)\"")
    cleanctx.run(bash: "git push branch release-script/\(version)-cleanup")
    // prompt to create PR - createPR()
}

// TODO: Create method to autmatically create PR - createPR()
func commitAndPush(_ version: String) {
    cleanctx.run(bash: "git add --all")
    print("Added changes")
    cleanctx.run(bash: "git commit -m \(version)")
    print("Committed new version")
//    print("Which remote would you like to push to? e.g. origin")
//    while let remote = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
//        cleanctx.run(bash: "git push \(remote) \(version)")
//        break
//    }
//    print("Would you like to create a PR? y/n")
//    while let pr = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
//        if pr == "y" {
//
//        }
//        break
//    }
    print("""
            🎉🎉 All Done! 🎉🎉 Don't forget to do the following:
            1. Create a PR on both the builder and the public repos
            2. Once PR is merged...Create a Release on GitHub
            3. Push to Cocoapods
            4. Update documentation/release notes
            5. Announce the new release in #support_mobile (slack)
          """)

    // Remind them to publish release/tag on github <--script using github api // https://github.community/t5/How-to-use-Git-and-GitHub/How-to-create-full-release-from-command-line-not-just-a-tag/td-p/6895
    // look in .ssh config for .pub (prompt for name)

}

// TODO:
func createPR() {

}

// TODO:
//runTests()
getRepoPaths()
guard let _ = builderRepoPath,
    let _ = publicRepoPath else {
        print("You must enter the full paths to both the public and builder repos. Try again, please.")
        exit(1)
}
greetAndSetDirectories()
checkVersion()
// checkForChanges() // TODO: fix?
guard let version = version else {
    print("You must enter a versoin number. Try again, please.")
    exit(1)
}
checkIfBranchAlreadyExists(version)
copySourceFiles()
checkForNewModules(version)
copyPackage()
copyPodspec(version)
commitAndPushToBuilder(version)
generateNewProject()
removeUneccessaryFiles()
commitAndPush(version)

RunLoop.main.run()

extension Dictionary where Key:Hashable {
    public func filterToDictionary <C: Collection> (keys: C) -> [Key:Value]
        where C.Iterator.Element == Key, C.IndexDistance == Int {

        var result = [Key:Value](minimumCapacity: keys.count)
        for key in keys { result[key] = self[key] }
        return result
    }
}
