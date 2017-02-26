//
//  WebUtils.h
//  DLGPlayer
//
//  Created by DeviLeo on 2017/2/26.
//  Copyright © 2017年 Liu Junqi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebUtils : NSObject

+ (BOOL)getIpAddress:(NSString **)ipv4 ipv6:(NSString **)ipv6;
+ (BOOL)getIpAddressByName:(NSString *)ifa_name ipv4:(NSString **)ipv4 ipv6:(NSString **)ipv6;

@end
