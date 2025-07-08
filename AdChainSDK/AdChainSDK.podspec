Pod::Spec.new do |spec|
  spec.name         = "AdChainSDK"
  spec.version      = "1.0.0"
  spec.summary      = "AdChain SDK for iOS - WebView-centric mobile advertising SDK"
  spec.description  = <<-DESC
                       AdChain SDK is a lightweight, WebView-centric mobile advertising SDK that provides
                       carousel ad display and WebView integration for iOS applications.
                       DESC
  spec.homepage     = "https://github.com/fly33499/adchain-ios-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "AdChain" => "sdk@adchain.com" }
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://github.com/fly33499/adchain-ios-sdk.git", :tag => "#{spec.version}" }
  spec.source_files = "AdChainSDK/Sources/**/*.{swift}"
  spec.swift_version = "5.0"
  spec.frameworks   = "UIKit", "WebKit", "AdSupport", "AppTrackingTransparency"
  spec.weak_frameworks = "AppTrackingTransparency"
end