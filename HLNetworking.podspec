Pod::Spec.new do |spec|
spec.name             = 'HLNetworking'
spec.version          = '1.0.3'
spec.license          = { :type => "MIT", :file => 'LICENSE' }
spec.homepage         = 'https://github.com/QianKun-HanLin/HLNetworking'
spec.authors          = {"wangshiyu13" => "wangshiyu13@163.com"}
spec.summary          = '基于AFNetworking的多范式网络请求管理器'
spec.source           =  {:git => 'https://github.com/QianKun-HanLin/HLNetworking', :tag => spec.version }
spec.source_files     = 'HLNetworking/Source/**/*.{h,m}'
spec.requires_arc     = true
spec.ios.deployment_target = '8.0'
spec.dependency 'AFNetworking', '~> 3.1.0'
end
