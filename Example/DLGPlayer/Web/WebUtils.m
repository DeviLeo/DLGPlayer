//
//  WebUtils.m
//  DLGPlayer
//
//  Created by DeviLeo on 2017/2/26.
//  Copyright © 2017年 Liu Junqi. All rights reserved.
//

#import "WebUtils.h"
#include <arpa/inet.h>
#include <ifaddrs.h>

@implementation WebUtils

+ (NSString *)getIpAddress {
#if TARGET_IPHONE_SIMULATOR
    return [WebUtils getIpAddressByName:@"en1"];
#else
    return [WebUtils getIpAddressByName:@"en0"];
#endif
}

+ (NSString *)getIpAddressByName:(NSString *)ifa_name {
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:ifa_name]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

@end
