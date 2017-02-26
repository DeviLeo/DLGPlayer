//
//  WebUtils.h
//  DLGPlayer
//
//  Created by DeviLeo on 2017/2/26.
//  Copyright © 2017年 Liu Junqi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebUtils : NSObject

+ (NSString *)getIpAddress;
+ (NSString *)getIpAddressByName:(NSString *)ifa_name;

@end
