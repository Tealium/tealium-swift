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
  s.version      = "2.6.2"
  s.summary      = "Tealium Swift Integration Library"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                   Supports Tealium's iQ and UDH suite of products on iOS, macOS, tvOS and watchOS
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
                           "craigrouse"   => "craig.rouse@tealium.com",
                           "christinasund"   => "christina.sund@tealium.com" }
  s.social_media_url   = "http://twitter.com/tealium"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #
  s.swift_version = "5.0"

  #  When using multiple platforms
  # iOS 11 is required for SwiftUI to be optionally included. See https://github.com/CocoaPods/CocoaPods/issues/8915. 
  # Clients can always have the Xcode project on iOS 9, and add a post-install script to lower this ios deployment target, 
  # but they have to specify iOS 11 on their podfile.
  s.ios.deployment_target = "11.0" 
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
    full.source_files  = "tealium/core/**/*.{swift,h,m}","tealium/collectors/**/*","tealium/dispatchers/**/*","tealium/scripts/*"
    full.ios.exclude_files = "tealium/scripts/*","tealium/collectors/crash/*","tealium/**/objc/include/*"
    full.tvos.exclude_files = "tealium/dispatchers/tagmanagement/*","tealium/dispatchers/remotecommands/*","tealium/collectors/attribution/*","tealium/scripts/*","tealium/collectors/location/*","tealium/collectors/autotracking/objc/include/*.{h,m}","tealium/core/objc/**/*"
    full.watchos.exclude_files = "tealium/dispatchers/tagmanagement/*","tealium/dispatchers/remotecommands/*","tealium/collectors/attribution/*","tealium/scripts/*","tealium/collectors/location/*","tealium/collectors/autotracking/**/*.{h,m}","tealium/core/objc/**/*"
    full.osx.exclude_files = "tealium/dispatchers/tagmanagement/*","tealium/dispatchers/remotecommands/*","tealium/collectors/attribution/*","tealium/scripts/*","tealium/collectors/location/*","tealium/collectors/autotracking/**/*.{h,m}","tealium/core/objc/**/*"
    full.resources = "tealium/core/devicedata/device-names.json"
  end

  s.subspec "Core" do |core|
    core.source_files = "tealium/core/**/*.{swift,h,m}"
    core.ios.exclude_files = "tealium/core/objc/include/*"
    core.tvos.exclude_files = "tealium/core/objc/**/*"
    core.watchos.exclude_files = "tealium/core/objc/**/*"
    core.osx.exclude_files = "tealium/core/objc/**/*"
    core.resources = "tealium/core/devicedata/device-names.json"
  end

  s.subspec "Attribution" do |attribution|
    attribution.source_files = "tealium/collectors/attribution/*"
    attribution.dependency "tealium-swift/Core"
  end

  s.subspec "Autotracking" do |autotracking|
    autotracking.source_files = "tealium/collectors/autotracking/**/*.{swift,h,m}"
    autotracking.ios.exclude_files = "tealium/collectors/autotracking/objc/include/*"
    autotracking.tvos.exclude_files = "tealium/collectors/autotracking/objc/include/*"
    autotracking.watchos.exclude_files = "tealium/collectors/autotracking/objc/**/*"
    autotracking.osx.exclude_files = "tealium/collectors/autotracking/objc/**/*"
    autotracking.dependency "tealium-swift/Core"
  end

  s.subspec "Collect" do |collect|
    collect.source_files = "tealium/dispatchers/collect/*"
    collect.dependency "tealium-swift/Core"
  end

  s.subspec "InAppPurchase" do |inapppurchase|
    inapppurchase.source_files = "tealium/collectors/inapppurchase/*"
    inapppurchase.dependency "tealium-swift/Core"
  end

  s.subspec "Lifecycle" do |lifecycle|
    lifecycle.source_files = "tealium/collectors/lifecycle/*"
    lifecycle.dependency "tealium-swift/Core"
  end

  s.subspec "Location" do |location|
    location.source_files = "tealium/collectors/location/*"
    location.dependency "tealium-swift/Core"
  end

  s.subspec "Media" do |media|
    media.source_files = "tealium/collectors/media/*"
    media.dependency "tealium-swift/Core"
  end

  s.subspec "RemoteCommands" do |remotecommands|
    remotecommands.source_files = "tealium/dispatchers/remotecommands/*"
    remotecommands.dependency "tealium-swift/Core"
  end

  s.subspec "TagManagement" do |tagmanagement|
    tagmanagement.source_files = "tealium/dispatchers/tagmanagement/*"
    tagmanagement.dependency "tealium-swift/Core"
  end

  s.subspec "VisitorService" do |visitorservice|
    visitorservice.source_files = "tealium/collectors/visitorservice/*"
    visitorservice.dependency "tealium-swift/Core"
  end
end
