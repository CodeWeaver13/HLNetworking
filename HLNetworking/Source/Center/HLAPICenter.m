//
//  HLAPICenter.m
//  HLNetworking+Lovek12
//
//  Created by wangshiyu13 on 2016/12/9.
//  Copyright © 2016年 mykj. All rights reserved.
//

#import "HLAPICenter.h"

static HLAPICenter *shared = nil;

@implementation HLAPICenter

- (HLBaseObjReformer *)defaultReformer {
    if (!_defaultReformer) {
        _defaultReformer = [[HLBaseObjReformer alloc] init];
    }
    return _defaultReformer;
}

+ (instancetype)defaultCenter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(shared == nil) {
            shared = [[self alloc] init];
        }
    });
    return shared;
}


+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if(shared == nil)
        {
            shared = [super allocWithZone:zone];
        }
    });
    return shared;
}


- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}
@end
