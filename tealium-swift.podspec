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
  s.version      = "1.6.4"
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
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = { :type => "Commercial", :file => "LICENSE.txt" }
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


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
  s.swift_version = '4.0'
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
  
  s.default_subspec = "Core"

  s.subspec "Core" do |core|
    core.source_files  = 'tealium/**/*'
    core.ios.exclude_files = 'tealium/crash/*', 'tealium/scripts/*'
    core.tvos.exclude_files = 'tealium/tagmanagement/TealiumTagManagementModule.swift', 'tealium/remotecommands/*', 'tealium/attribution/*', "tealium/crash/*", 'tealium/scripts/*'
    core.watchos.exclude_files = 'tealium/tagmanagement/TealiumTagManagementModule.swift', 'tealium/autotracking/*', 'tealium/connectivity/*', 'tealium/remotecommands/*', 'tealium/attribution/*', "tealium/crash/*", 'tealium/scripts/*'
    core.osx.exclude_files = 'tealium/tagmanagement/TealiumTagManagementModule.swift', 'tealium/autotracking/*', 'tealium/remotecommands/*', 'tealium/attribution/*', "tealium/crash/*", 'tealium/scripts/*'
  end

  s.subspec "Crash" do |crash|
    crash.platform = :ios, "9.0"
    crash.ios.source_files = "tealium/crash/*"
    crash.ios.dependency "tealium-swift/Core"
    crash.ios.dependency "TealiumCrashReporter"
    crash.tvos.exclude_files = "tealium/crash/*"
    crash.watchos.exclude_files = "tealium/crash/*"
    crash.osx.exclude_files = "tealium/crash/*"
  end
  
  # s.ios.dependency "TealiumCrashReporter"

end
