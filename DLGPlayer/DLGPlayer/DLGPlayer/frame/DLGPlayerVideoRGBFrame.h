//
//  DLGPlayerVideoRGBFrame.h
//  DLGPlayer
//
//  Created by Liu Junqi on 09/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGPlayerVideoFrame.h"

@interface DLGPlayerVideoRGBFrame : DLGPlayerVideoFrame

@property (nonatomic) NSUInteger linesize;
@property (nonatomic) BOOL hasAlpha;

@end
