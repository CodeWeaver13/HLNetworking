//
//  HLAPIRequest_InternalParams.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLAPIRequest.h"
NS_ASSUME_NONNULL_BEGIN
@interface HLAPIRequest ()
// readOnly property
@property (nonatomic, strong, nullable) Class objClz;
@property (nonatomic, assign) BOOL useDefaultParams;
@property (nonatomic, weak, nullable) id<HLReformerDelegate> objReformerDelegate;
@property (nonatomic, assign) HLRequestMethodType requestMethodType;
@property (nonatomic, assign) HLRequestSerializerType requestSerializerType;
@property (nonatomic, assign) HLResponseSerializerType responseSerializerType;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSObject *> *parameters;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *header;
@property (nonatomic, copy) NSSet *accpetContentTypes;

@property (nonatomic, copy, nullable) HLRequestConstructingBodyBlock requestConstructingBodyBlock;
@end
NS_ASSUME_NONNULL_END
