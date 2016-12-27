Pod::Spec.new do |s|
  s.name             = 'HLNetworking'
  s.version          = '1.1.5'
  s.license          = { :type => "MIT", :file => 'LICENSE' }
  s.homepage         = 'https://github.com/QianKun-HanLin/HLNetworking'
  s.authors          = {"wangshiyu13" => "wangshiyu13@163.com"}
  s.summary          = '基于AFNetworking的多范式网络请求管理器'
  s.source           =  {:git => 'https://github.com/QianKun-HanLin/HLNetworking.git', :tag => spec.version }
  s.source_files     = 'HLNetworking/Source/**/*.{h,m}'
  s.requires_arc     = true
  s.ios.deployment_target = '8.0'
  s.dependency 'AFNetworking', '~> 3.1.0'
  s.subspec 'Center' do |ss|
    ss.source_files = 'HLNetworking/Source/Center/*.{h,m}'
    ss.dependency = 'YYModel'
  end
end
