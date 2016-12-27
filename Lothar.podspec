Pod::Spec.new do |spec|
spec.name             = 'Lothar'
spec.version          = '1.0.4'
spec.license          = { :type => "MIT", :file => 'LICENSE' }
spec.homepage         = 'https://git.coding.net/hlpubliclibrary/Lothar'
spec.authors          = {"wangshiyu13" => "wangshiyu13@163.com"}
spec.summary          = '基于CTMediator的组件化中间件'
spec.source           =  {:git => 'git@git.coding.net:hlpubliclibrary/Lothar.git', :tag => spec.version }
spec.source_files     = 'Lothar/Source/**/*.{h,m}'
spec.requires_arc     = true
spec.ios.deployment_target = '8.0'
end
