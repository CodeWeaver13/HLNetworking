//
//  UIDevice+deviceInfo.h
//  HLNetworking
//
//  Created by Georg Kitz on 20.08.11.
//  Copyright 2011 Aurora Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (deviceInfo)
- (NSString *) hl_uuid;
- (NSString *) hl_udid;
- (NSString *) hl_macaddress;
- (NSString *) hl_macaddressMD5;
- (NSString *) hl_machineType;
@end
