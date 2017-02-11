//
//  DLGPlayerViewController.h
//  DLGPlayer
//
//  Created by Liu Junqi on 06/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DLGPlayer.h"

@interface DLGPlayerViewController : UIViewController

@property (nonatomic) NSString *url;
@property (nonatomic) BOOL autoplay;
@property (nonatomic) BOOL repeat;
@property (nonatomic) BOOL preventFromScreenLock;
@property (nonatomic) BOOL restorePlayAfterAppEnterForeground;

- (void)open;
- (void)close;
- (void)play;
- (void)pause;

@end
