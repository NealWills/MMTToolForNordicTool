#
# Be sure to run `pod lib lint MMTToolForNordicTool.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MMTToolForNordicTool'
  s.version          = '1.0.0'
  s.summary          = 'A Bluetooth tool library for Nordic chip devices with DFU support.'

  s.description      = <<-DESC
MMTToolForNordicTool is a comprehensive Bluetooth tool library for Nordic chip devices. 
It provides device scanning, connection management, and DFU (Device Firmware Update) functionality. 
Features include MAC address extraction, RSSI signal strength sorting, service/characteristic scanning, 
and complete DFU upgrade workflow support.
                       DESC

  s.homepage         = 'https://github.com/NealWills/MMTToolForNordicTool'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'NealWills' => 'aoiiiiyuki@outlook.com' }
  s.source           = { :git => 'https://github.com/NealWills/MMTToolForNordicTool.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'MMTToolForNordicTool/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MMTToolForNordicTool' => ['MMTToolForNordicTool/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  
  s.frameworks = 'CoreBluetooth', 'Foundation'
  
  s.dependency 'NordicDFU', '~> 4.15'
  s.dependency 'ZIPFoundation', '~> 0.9'
  
end
