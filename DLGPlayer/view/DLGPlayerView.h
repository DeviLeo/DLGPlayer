//
//  DLGPlayerView.h
//  DLGPlayer
//
//  Created by Liu Junqi on 05/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DLGPlayerVideoFrame;

@interface DLGPlayerView : UIView

@property (nonatomic) CGSize contentSize;
@property (nonatomic) CGFloat rotation;
@property (nonatomic) BOOL isYUV;
@property (nonatomic) BOOL keepLastFrame;

- (void)render:(DLGPlayerVideoFrame *)frame;
- (void)clear;

@end
