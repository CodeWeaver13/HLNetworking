//
//  HLBaseObjReformer.m
//  HLNetworking+Lovek12
//
//  Created by wangshiyu13 on 2016/12/9.
//  Copyright © 2016年 mykj. All rights reserved.
//

#import "HLBaseObjReformer.h"
#import <YYModel/YYModel.h>

@implementation HLBaseObjReformer
- (id)objReformerWithAPI:(HLAPI *)api andResponseObject:(id)responseObject andError:(NSError *)error {
    if (responseObject) {
        return [api.objClz yy_modelWithJSON:responseObject];
    } else {
        return [[api.objClz alloc] init];
    }
}
@end
