//
//  DLGPlayerFrame.m
//  DLGPlayer
//
//  Created by Liu Junqi on 08/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGPlayerFrame.h"

@implementation DLGPlayerFrame

- (id)init {
    self = [super init];
    if (self) {
        _type = kDLGPlayerFrameTypeNone;
        _data = nil;
    }
    return self;
}

@end
