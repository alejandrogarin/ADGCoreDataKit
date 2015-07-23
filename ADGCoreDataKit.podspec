#
# Be sure to run `pod lib lint ADGCoreDataKit.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ADGCoreDataKit"
  s.version          = "0.1.0"
  s.summary          = "Apple CoreData made easy."
  s.description      = <<-DESC
                       An interface to Apple Core Data
                       DESC
  s.homepage         = "https://github.com/alejandrogarin/ADGCoreDataKit"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Alejandro Garin" => "agarin@gmail.com" }
  s.source           = { :git => "https://github.com/alejandrogarin/ADGCoreDataKit.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/alejandrogarin'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'ADGCoreDataKit' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreData'
end
