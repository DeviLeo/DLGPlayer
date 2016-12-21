//
//  DLGPlayerFrame.h
//  DLGPlayer
//
//  Created by Liu Junqi on 08/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    kDLGPlayerFrameTypeNone,
    kDLGPlayerFrameTypeVideo,
    kDLGPlayerFrameTypeAudio
} DLGPlayerFrameType;

@interface DLGPlayerFrame : NSObject

@property (nonatomic) DLGPlayerFrameType type;
@property (nonatomic) NSData *data;
@property (nonatomic) double position;
@property (nonatomic) double duration;

@end
