Pod::Spec.new do |spec|
  spec.name             = 'HLNetworking'
  spec.version          = '2.0.0.beta1'
  spec.license          = { :type => "MIT", :file => 'LICENSE' }
  spec.homepage         = 'https://github.com/QianKun-HanLin/HLNetworking'
  spec.authors          = {"wangshiyu13" => "wangshiyu13@163.com"}
  spec.summary          = '基于AFNetworking的高阶网络请求管理器'
  spec.source           =  {
      :git => 'https://github.com/QianKun-HanLin/HLNetworking.git',
      :tag => spec.version,
      :submodules => true
   }
  spec.requires_arc     = true
  spec.ios.deployment_target = '8.0'
  spec.default_subspec = 'Core'
  spec.resource  = "HLNetworking/Source/Logger/iPhoneTypeDefine.plist"

  spec.subspec 'Core' do |core|

    core.source_files = 'HLNetworking/Source/HLNetworking.h', 'HLNetworking/Source/Generator/**/*.{h,m}', 'HLNetworking/Source/Manager/**/*.{h,m}', 'HLNetworking/Source/Engine/**/*.{h,m}', 'HLNetworking/Source/Logger/**/*.{h,m}', 'HLNetworking/Source/Config/**/*.{h,m}'

    core.dependency 'AFNetworking', '~> 3.1.0'

  end

  spec.subspec 'Center' do |center|

    center.source_files = 'HLNetworking/Source/Center/*.{h,m}'

    center.dependency 'HLNetworking/Core'

    center.dependency 'YYModel'
    
  end
end
