//
//  DLGPlayerVideoFrame.h
//  DLGPlayer
//
//  Created by Liu Junqi on 05/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGPlayerFrame.h"
#import <OpenGLES/ES2/gl.h>

typedef enum : NSUInteger {
    kDLGPlayerVideoFrameTypeNone,
    kDLGPlayerVideoFrameTypeRGB,
    kDLGPlayerVideoFrameTypeYUV
} DLGPlayerVideoFrameType;

@interface DLGPlayerVideoFrame : DLGPlayerFrame

@property (nonatomic) DLGPlayerVideoFrameType videoType;
@property (nonatomic) int width;
@property (nonatomic) int height;

- (BOOL)prepareRender:(GLuint)program;

@end
