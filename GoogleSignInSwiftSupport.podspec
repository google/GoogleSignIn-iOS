Pod::Spec.new do |s|
  s.name = 'GoogleSignInSwiftSupport'
  s.version = '8.0.0'
  s.swift_version = '5.0'
  s.summary = 'Adds Swift-focused support for Google Sign-In.'
  s.description = 'Additional Swift support for the Google Sign-In SDK.'
  s.homepage = 'https://developers.google.com/identity/sign-in/ios/'
  s.license = { :type => 'Apache', :file => 'LICENSE' }
  s.authors = 'Google LLC'
  s.source = {
    :git => 'https://github.com/google/GoogleSignIn-iOS.git',
    :tag => s.version.to_s
  }
  ios_deployment_target = '13.0'
  macos_deployment_target = '10.15' 
  s.ios.deployment_target = ios_deployment_target
  s.osx.deployment_target = macos_deployment_target
  s.module_name = 'GoogleSignInSwift'
  s.prefix_header_file = false
  s.source_files = [
    'GoogleSignInSwift/Sources/*.swift',
  ]
  s.frameworks = [
    'CoreGraphics',
    'SwiftUI',
  ]
  s.dependency 'GoogleSignIn', '~> 8.0'
  s.resource_bundles = {
    'GoogleSignInSwiftSupport_Privacy' => 'GoogleSignInSwift/Sources/Resources/PrivacyInfo.xcprivacy'
  }
  s.test_spec 'unit' do |unit_tests|
    unit_tests.platforms = {
      :ios => ios_deployment_target,
      :osx => macos_deployment_target,
    }
    unit_tests.source_files = [
      'GoogleSignInSwift/Tests/Unit/*.swift',
    ]
    unit_tests.requires_app_host = true
  end
end
