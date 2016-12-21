//
//  DLGPlayerVideoFrame.m
//  DLGPlayer
//
//  Created by Liu Junqi on 05/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGPlayerVideoFrame.h"

@implementation DLGPlayerVideoFrame

- (id)init {
    self = [super init];
    if (self) {
        self.type = kDLGPlayerFrameTypeVideo;
    }
    return self;
}

- (BOOL)prepareRender:(GLuint)program {
    return NO;
}

@end
