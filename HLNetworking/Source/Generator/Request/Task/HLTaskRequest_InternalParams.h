//
//  HLTaskRequest_InternalParams.h
//  HLNetworking
//
//  Created by wangshiyu13 on 2017/1/23.
//  Copyright © 2017年 wangshiyu13. All rights reserved.
//

#import "HLTaskRequest.h"

@interface HLTaskRequest ()
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *resumePath;
@property (nonatomic, assign)HLRequestTaskType requestTaskType;
@end
