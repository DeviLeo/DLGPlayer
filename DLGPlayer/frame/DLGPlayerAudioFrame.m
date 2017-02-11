//
//  DLGPlayerAudioFrame.m
//  DLGPlayer
//
//  Created by Liu Junqi on 08/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGPlayerAudioFrame.h"

@implementation DLGPlayerAudioFrame

- (id)init {
    self = [super init];
    if (self) {
        self.type = kDLGPlayerFrameTypeAudio;
    }
    return self;
}

@end
