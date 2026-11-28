#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint eventide_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'eventide_ios'
  s.version          = '1.0.0'
  s.summary          = 'iOS implementation of the Eventide Flutter calendar plugin'
  s.description      = <<-DESC
Eventide provides a easy-to-use flutter interface to access & modify native device calendars.
                       DESC
  s.homepage         = 'https://github.com/sncf-connect-tech/eventide'
  s.license          = { :type => "MIT", :file => '../LICENSE' }
  s.author           = { 'SNCF Connect & Tech' => 'alexis.choupault@connect-tech.sncf' }
  s.source           = { :git => 'https://github.com/sncf-connect-tech/eventide.git', :tag => s.version.to_s }
  s.source_files = 'eventide_ios/Sources/eventide_ios/**/*.swift'
  s.resource_bundles = {'eventide_ios_privacy' => ['eventide_ios/Sources/eventide_ios/PrivacyInfo.xcprivacy']}
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
