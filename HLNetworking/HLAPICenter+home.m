//
//  HLAPICenter+home.m
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/2.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLAPICenter+home.h"

@implementation HLAPICenter (home)
HLStrongSynthesize(home, [HLAPI API]
                   .setMethod(GET)
                   .setPath(@"index.php?r=resource/index-app")
                   .setResponseClass(@"HLHomeModel")
                   .setObjReformerDelegate(self.defaultReformer))

@end
