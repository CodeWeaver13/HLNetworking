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
- (id)reformerObject:(id)responseObject andError:(NSError *)error atRequest:(HLAPIRequest *)api {
    if (api.objClz && ![NSStringFromClass(api.objClz) isEqualToString:@"NSObject"]) {
        if (responseObject) {
            return [api.objClz yy_modelWithJSON:responseObject];
        }
    }
#if DEBUG
    NSLog(@"该对象无法转换，api = %@", api);
#endif
    return nil;
}
@end
