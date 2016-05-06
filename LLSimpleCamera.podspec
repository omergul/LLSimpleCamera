Pod::Spec.new do |s|
  s.name         = "LLSimpleCamera"
  s.version      = "5.0.0"
  s.summary      = "LLSimpleCamera: A simple customizable camera - video recorder control."
  s.description  = <<-DESC
                   LLSimpleCamera is a library for creating a customized camera screens similar to snapchat's. You don't have to present the camera in a new view controller. You can capture images or record videos very easily.

LLSimpleCamera:
will let you easily capture photos or record videos
handles the position and flash of the camera
hides the nitty gritty details from the developer
                   DESC

  s.homepage     = "https://github.com/omergul123/LLSimpleCamera"
  s.license      = { :type => 'APACHE', :file => 'LICENSE' }
  s.author       = { "Ömer Faruk Gül" => "omergul123@gmail.com" }
  s.platform     = :ios,'7.0'
  s.source       = { :git => "https://github.com/omergul123/LLSimpleCamera.git", :tag => "v5.0.0" }
  s.source_files  = 'LLSimpleCamera/*.{h,m}'
  s.requires_arc = true
  s.framework = 'AVFoundation'
end
