//
//  DLGPlayerAudioManager.h
//  DLGPlayer
//
//  Created by Liu Junqi on 08/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DLGPlayerAudioManagerFrameReaderBlock)(float *data, UInt32 num, UInt32 channels);

@interface DLGPlayerAudioManager : NSObject

@property (nonatomic, copy) DLGPlayerAudioManagerFrameReaderBlock frameReaderBlock;
@property (nonatomic) float volume;

- (BOOL)open:(NSError **)error;
- (BOOL)play;
- (BOOL)play:(NSError **)error;
- (BOOL)pause;
- (BOOL)pause:(NSError **)error;
- (BOOL)close;
- (BOOL)close:(NSArray<NSError *> **)errors;

- (double)sampleRate;
- (UInt32)channels;

@end
