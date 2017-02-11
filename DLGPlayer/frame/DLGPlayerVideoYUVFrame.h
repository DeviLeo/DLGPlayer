//
//  DLGPlayerVideoYUVFrame.h
//  DLGPlayer
//
//  Created by Liu Junqi on 09/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGPlayerVideoFrame.h"

@interface DLGPlayerVideoYUVFrame : DLGPlayerVideoFrame

@property (nonatomic) NSData *Y;    // Luma
@property (nonatomic) NSData *Cb;   // Chroma Blue
@property (nonatomic) NSData *Cr;   // Chroma Red

@end
