//
//  DLGPlayerUtils.h
//  DLGPlayer
//
//  Created by Liu Junqi on 05/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLGPlayerUtils : NSObject

+ (BOOL)createError:(NSError **)error withDomain:(NSString *)domain andCode:(NSInteger)code andMessage:(NSString *)message;
+ (BOOL)createError:(NSError **)error withDomain:(NSString *)domain andCode:(NSInteger)code andMessage:(NSString *)message andRawError:(NSError *)rawError;
+ (NSString *)localizedString:(NSString *)name;
+ (NSString *)durationStringFromSeconds:(int)seconds;

@end
