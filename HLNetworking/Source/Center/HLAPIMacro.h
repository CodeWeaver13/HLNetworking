//
//  HLAPIMacro.h
//  HLNetworking+Lovek12
//
//  Created by wangshiyu13 on 2016/12/10.
//  Copyright © 2016年 mykj. All rights reserved.
//

#ifndef HLAPIMacro_h
#define HLAPIMacro_h

#import <objc/runtime.h>

#define metamacro_concat(A, B) \
metamacro_concat_(A, B)
#define metamacro_concat_(A, B) A ## B

#define HLStrongProperty(name) \
@property (nonatomic, strong, setter=set__nonuse__##name:, getter=__nonuse__##name) HLAPI *name; \
+ (HLAPI *)name;

#define HLStrongSynthesize(name, api) \
static void *name##AssociatedKey = #name "associated"; \
- (void)set__nonuse__##name:(HLAPI *)name { \
objc_setAssociatedObject(self, name##AssociatedKey, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
} \
\
- (HLAPI *)__nonuse__##name { \
id _##name = objc_getAssociatedObject(self, name##AssociatedKey); \
if (!_##name) { \
_##name = api; \
} \
return _##name; \
} \
+ (HLAPI *)name { \
return [[self defaultCenter] __nonuse__##name];\
}

#endif /* HLAPIMacro_h */
