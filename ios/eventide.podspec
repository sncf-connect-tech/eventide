#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint eventide.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'eventide'
  s.version          = '1.0.0'
  s.summary          = 'Flutter calendar plugin'
  s.description      = <<-DESC
Eventide provides a easy-to-use flutter interface to access & modify native device calendars.
                       DESC
  s.homepage         = 'https://github.com/sncf-connect-tech/eventide'
  s.license          = { :type => "MIT", :file => '../LICENSE' }
  s.author           = { 'SNCF Connect & Tech' => 'alexis.choupault@connect-tech.sncf' }
  s.source           = { :git => 'https://github.com/sncf-connect-tech/eventide.git', :tag => s.version.to_s }
  s.source_files = 'eventide/Sources/eventide/**/*.swift'
  s.resource_bundles = {'eventide_privacy' => ['eventide/Sources/eventide/PrivacyInfo.xcprivacy']}
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'eventide_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
