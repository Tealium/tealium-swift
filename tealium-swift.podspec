#
#  Be sure to run `pod spec lint tealium-swift.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "tealium-swift"
  s.module_name  = "TealiumSwift"
  s.version      = "1.7.0"
  s.summary      = "Tealium Swift Integration Library"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                   Supports Tealium's iQ and UDH suite of products on iOS, MacOS, tvOS and watchOS
                   DESC

  s.homepage     = "https://github.com/Tealium/tealium-swift"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = { :type => "Commercial", :file => "LICENSE.txt" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.authors            = { "Tealium Inc." => "tealium@tealium.com",
                           "craigrouse"   => "craig.rouse@tealium.com" }
  s.social_media_url   = "http://twitter.com/tealium"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #
  s.swift_version = "4.0"
  s.platform     = :ios, "9.0"
  s.platform     = :osx, "10.11"
  s.platform     = :watchos, "3.0"
  s.platform     = :tvos, "9.0"

  #  When using multiple platforms
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/Tealium/tealium-swift.git", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #
  
  s.default_subspec = "TealiumFull"

  s.subspec "TealiumFull" do |full|
    full.source_files  = "tealium/appdata/*", "tealium/core/*", "tealium/attribution/*", "tealium/autotracking/*", "tealium/collect/*", "tealium/connectivity/*", "tealium/consentmanager/*", "tealium/datasource/*", "tealium/defaultsstorage/*", "tealium/persistentdata/*", "tealium/delegate/*", "tealium/devicedata/TealiumDeviceData.swift", "tealium/devicedata/TealiumDeviceDataModule.swift", "tealium/dispatchqueue/*", "tealium/filestorage/*", "tealium/lifecycle/*", "tealium/logger/*", "tealium/remotecommands/*", "tealium/tagmanagement/*", "tealium/volatiledata/*", "tealium/crash/*"
    full.ios.exclude_files = "tealium/scripts/*"
    full.ios.dependency "TealiumCrashReporter"
    full.tvos.exclude_files = "tealium/tagmanagement/*", "tealium/remotecommands/*", "tealium/attribution/*", "tealium/crash/*", "tealium/scripts/*"
    full.watchos.exclude_files = "tealium/tagmanagement/*", "tealium/autotracking/*", "tealium/connectivity/*", "tealium/remotecommands/*", "tealium/attribution/*", "tealium/crash/*", "tealium/scripts/*"
    full.osx.exclude_files = "tealium/tagmanagement/*", "tealium/autotracking/*", "tealium/remotecommands/*", "tealium/attribution/*", "tealium/crash/*", "tealium/scripts/*"
    full.resources = "tealium/devicedata/device-names.json"
  end

  s.subspec "Core" do |core|
    core.source_files  = "tealium/core/*"
  end

  s.subspec "TealiumAppData" do |appdata|
    appdata.source_files = "tealium/appdata/*"
    appdata.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumAttribution" do |attribution|
    attribution.platform = :ios, "9.0"
    attribution.source_files = "tealium/attribution/*"
    attribution.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumAutotracking" do |autotracking|
    autotracking.ios.deployment_target = "9.0"
    autotracking.tvos.deployment_target = "9.0"
    autotracking.source_files = "tealium/autotracking/*"
    autotracking.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumCollect" do |collect|
    collect.source_files = "tealium/collect/*"
    collect.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumConnectivity" do |connectivity|
    connectivity.ios.deployment_target = "9.0"
    connectivity.osx.deployment_target = "10.11"
    connectivity.tvos.deployment_target = "9.0"
    connectivity.source_files = "tealium/connectivity/*"
    connectivity.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumConsentManager" do |consentmanager|
    consentmanager.source_files = "tealium/consentmanager/*"
    consentmanager.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumDataSource" do |datasource|
    datasource.source_files = "tealium/datasource/*"
    datasource.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumDefaultsStorage" do |defaultsstorage|
    defaultsstorage.source_files = "tealium/defaultsstorage/*", "tealium/persistentdata/*"
    defaultsstorage.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumDelegate" do |delegate|
    delegate.source_files = "tealium/delegate/*"
    delegate.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumDeviceData" do |devicedata|
    devicedata.source_files = "tealium/devicedata/TealiumDeviceData.swift", "tealium/devicedata/TealiumDeviceDataModule.swift"
    devicedata.dependency "tealium-swift/Core"
    devicedata.resources = "tealium/devicedata/device-names.json"
  end

  s.subspec "TealiumDispatchQueue" do |dispatchqueue|
    dispatchqueue.source_files = "tealium/dispatchqueue/*"
    dispatchqueue.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumFileStorage" do |filestorage|
    filestorage.source_files = "tealium/filestorage/*", "tealium/persistentdata/*"
    filestorage.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumLifecycle" do |lifecycle|
    lifecycle.source_files = "tealium/lifecycle/*"
    lifecycle.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumLogger" do |logger|
    logger.source_files = "tealium/logger/*"
    logger.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumRemoteCommands" do |remotecommands|
    remotecommands.platform = :ios, "9.0"
    remotecommands.source_files = "tealium/remotecommands/*"
    remotecommands.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumTagManagement" do |tagmanagement|
    tagmanagement.platform = :ios, "9.0"
    tagmanagement.source_files = "tealium/tagmanagement/*"
    tagmanagement.dependency "tealium-swift/Core"
  end

  s.subspec "TealiumVolatileData" do |volatiledata|
    volatiledata.source_files = "tealium/volatiledata/*"
    volatiledata.dependency "tealium-swift/Core"
  end

  s.subspec "Crash" do |crash|
    crash.platform = :ios, "9.0"
    crash.ios.source_files = "tealium/crash/*"
    crash.ios.dependency "tealium-swift/Core"
    crash.ios.dependency "tealium-swift/TealiumAppData"
    crash.ios.dependency "tealium-swift/TealiumDeviceData"
    crash.ios.dependency "TealiumCrashReporter"
    crash.tvos.exclude_files = "tealium/crash/*"
    crash.watchos.exclude_files = "tealium/crash/*"
    crash.osx.exclude_files = "tealium/crash/*"
  end

end
