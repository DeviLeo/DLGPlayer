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
#include <netinet/in.h>
#include <net/if.h>

@implementation WebUtils

+ (BOOL)getIpAddress:(NSString **)ipv4 ipv6:(NSString **)ipv6 {
#if TARGET_IPHONE_SIMULATOR
    return [WebUtils getIpAddressByName:@"en1" ipv4:ipv4 ipv6:ipv6];
#else
    return [WebUtils getIpAddressByName:@"en0" ipv4:ipv4 ipv6:ipv6];
#endif
}

+ (BOOL)getIpAddressByName:(NSString *)ifa_name ipv4:(NSString **)ipv4 ipv6:(NSString **)ipv6 {
    NSString *ipv4addr = nil;
    NSString *ipv6addr = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t family = temp_addr->ifa_addr->sa_family;
            if(family == AF_INET) {
                NSString *ifa = [NSString stringWithUTF8String:temp_addr->ifa_name];
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([ifa isEqualToString:ifa_name]) {
                    // Get NSString from C String
                    char ip[INET_ADDRSTRLEN];
                    struct sockaddr_in *addr = (struct sockaddr_in *)temp_addr->ifa_addr;
                    const char *ch = inet_ntop(AF_INET, &addr->sin_addr, ip, INET_ADDRSTRLEN);
                    ipv4addr = [NSString stringWithUTF8String:ch];
                    if ([ipv4addr rangeOfString:@"169.254."].location == 0) ipv4addr = nil;
                }
            } else if (family == AF_INET6) {
                NSString *ifa = [NSString stringWithUTF8String:temp_addr->ifa_name];
                
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([ifa isEqualToString:ifa_name]) {
                    // Get NSString from C String
                    char ip[INET6_ADDRSTRLEN];
                    struct sockaddr_in6 *addr = (struct sockaddr_in6 *)temp_addr->ifa_addr;
                    const char *ch = inet_ntop(AF_INET6, &addr->sin6_addr, ip, INET6_ADDRSTRLEN);
                    ipv6addr = [NSString stringWithUTF8String:ch];
                    if ([ipv6addr rangeOfString:@"fe80::" options:NSCaseInsensitiveSearch].location == 0) ipv6addr = nil;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    if (ipv4addr == nil && ipv6addr == nil) return NO;
    
    if (ipv4 != nil) *ipv4 = ipv4addr;
    if (ipv6 != nil) *ipv6 = ipv6addr;
    return YES;
}

@end
