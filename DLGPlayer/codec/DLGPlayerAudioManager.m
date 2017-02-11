//
//  DLGPlayerAudioManager.m
//  DLGPlayer
//
//  Created by Liu Junqi on 08/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGPlayerAudioManager.h"
#import "DLGPlayerUtils.h"
#import "DLGPlayerDef.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>

#define MAX_FRAME_SIZE  4096
#define MAX_CHANNEL     2
#define PREFERRED_SAMPLE_RATE   44100
#define PREFERRED_BUFFER_DURATION 0.023

static OSStatus audioUnitRenderCallback(void *inRefCon,
                                        AudioUnitRenderActionFlags *ioActionFlags,
                                        const AudioTimeStamp *inTimeStamp,
                                        UInt32 inBusNumber,
                                        UInt32 inNumberFrames,
                                        AudioBufferList *ioData);

@interface DLGPlayerAudioManager () {
    BOOL _opened;
    BOOL _shouldPlayAfterInterruption;
    BOOL _playing;
    double _sampleRate;
    UInt32 _bitsPerChannel;
    UInt32 _channelsPerFrame;
    AudioUnit _audioUnit;
    float *_audioData;
}

@end

@implementation DLGPlayerAudioManager

- (id)init {
    self = [super init];
    if (self) {
        [self initVars];
    }
    return self;
}

- (void)initVars {
    _opened = NO;
    _shouldPlayAfterInterruption = NO;
    _playing = NO;
    _sampleRate = 0;
    _bitsPerChannel = 0;
    _channelsPerFrame = 0;
    _audioUnit = NULL;
    _audioData = (float *)calloc(MAX_FRAME_SIZE * MAX_CHANNEL, sizeof(float));
    _frameReaderBlock = nil;
}

- (void)dealloc {
    [self close];
    if (_audioData != NULL) {
        free(_audioData);
        _audioData = NULL;
    }
}

/*
 * https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/ConstructingAudioUnitApps/ConstructingAudioUnitApps.html
 */
- (BOOL)open:(NSError **)error {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    if (![session setCategory:AVAudioSessionCategoryPlayback error:error]) {
        return NO;
    }
    
    NSTimeInterval prefferedIOBufferDuration = PREFERRED_SAMPLE_RATE;
    if (![session setPreferredIOBufferDuration:prefferedIOBufferDuration error:error]) {
        NSLog(@"setPreferredIOBufferDuration: %.4f, error: %@", prefferedIOBufferDuration, *error);
    }
    
    double prefferedSampleRate = PREFERRED_SAMPLE_RATE;
    if (![session setPreferredSampleRate:prefferedSampleRate error:error]) {
        NSLog(@"setPreferredSampleRate: %.4f, error: %@", prefferedSampleRate, *error);
    }
    
    if (![session setActive:YES error:error]) {
        return NO;
    }
    
    AVAudioSessionRouteDescription *route = session.currentRoute;
    if (route.outputs.count == 0) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeNoAudioOuput
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_NO_AUDIO_OUTPUT"]];
        return NO;
    }
    
    NSInteger channels = session.outputNumberOfChannels;
    if (channels <= 0) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeNoAudioChannel
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_NO_AUDIO_CHANNEL"]];
        return NO;
    }
    
    double sampleRate = session.sampleRate;
    if (sampleRate <= 0) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeNoAudioSampleRate
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_NO_AUDIO_SAMPLE_RATE"]];
        return NO;
    }
    
    float volume = session.outputVolume;
    if (volume < 0) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeNoAudioVolume
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_NO_AUDIO_VOLUME"]];
        return NO;
    }
    
    if (![self initAudioUnitWithSampleRate:sampleRate andRenderCallback:audioUnitRenderCallback error:error]) {
        return NO;
    }
    
    _sampleRate = sampleRate;
    _volume = volume;
    
    return YES;
}

- (BOOL)initAudioUnitWithSampleRate:(double)sampleRate andRenderCallback:(AURenderCallback)renderCallback error:(NSError **)error {
    AudioComponentDescription descr = {0};
    descr.componentType = kAudioUnitType_Output;
    descr.componentSubType = kAudioUnitSubType_RemoteIO;
    descr.componentManufacturer = kAudioUnitManufacturer_Apple;
    descr.componentFlags = 0;
    descr.componentFlagsMask = 0;
    
    AudioUnit audioUnit = NULL;
    AudioComponent component = AudioComponentFindNext(NULL, &descr);
    OSStatus status = AudioComponentInstanceNew(component, &audioUnit);
    if (status != noErr) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:status
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_FAILED_TO_GET_AUDIO_UNIT"]];
        return NO;
    }
    
    AudioStreamBasicDescription streamDescr = {0};
    UInt32 size = sizeof(AudioStreamBasicDescription);
    status = AudioUnitGetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,
                                  0, &streamDescr, &size);
    if (status != noErr) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:status
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_FAILED_TO_GET_AUDIO_STREAM_DESCRIPTION"]];
        return NO;
    }
    
    streamDescr.mSampleRate = sampleRate;
    status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,
                                  0, &streamDescr, size);
    if (status != noErr) {
        NSLog(@"FAILED to set audio sample rate: %f, error: %d", sampleRate, (int)status);
    }
    
    _bitsPerChannel = streamDescr.mBitsPerChannel;
    _channelsPerFrame = streamDescr.mChannelsPerFrame;
    
    AURenderCallbackStruct renderCallbackStruct;
    renderCallbackStruct.inputProc = renderCallback;
    renderCallbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
    if (status != noErr) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:status
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_FAILED_TO_SET_AUDIO_RENDER_CALLBACK"]];
        return NO;
    }
    
    status = AudioUnitInitialize(audioUnit);
    if (status != noErr) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:status
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_FAILED_TO_INIT_AUDIO_UNIT"]];
        return NO;
    }
    
    _audioUnit = audioUnit;
    
    return YES;
}

- (void)close {
    if (_opened) {
        [self pause];
        
        [self unregisterNotifications];
        
        OSStatus status = AudioUnitUninitialize(_audioUnit);
        if (status != noErr) {
            NSLog(@"FAILED to uninitialize audio unit. Error: %zd", status);
        }
        
        status = AudioComponentInstanceDispose(_audioUnit);
        if (status != noErr) {
            NSLog(@"FAILED to dispose audio unit. Error: %zd", status);
        }
        
        NSError *error = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        if (![session setActive:NO error:&error]) {
            NSLog(@"FAILED to deactive audio session, error: %@", error);
        }
        
        _opened = NO;
    }
}

- (void)play {
    if (!_opened) {
        NSError *error = nil;
        if ([self open:&error]) {
            _opened = YES;
            OSStatus status = AudioOutputUnitStart(_audioUnit);
            _playing = (status == noErr);
            if (!_playing) {
                NSLog(@"Cannot start to play audio");
            } else {
                [self registerNotifications];
            }
        } else {
            NSLog(@"Failed to open audio, error: %@", error);
        }
    } else {
        _opened = YES;
        OSStatus status = AudioOutputUnitStart(_audioUnit);
        _playing = (status == noErr);
        if (!_playing) {
            NSLog(@"Cannot start to play audio");
        } else {
            [self registerNotifications];
        }
    }
}

- (void)pause {
    if (_playing) {
        OSStatus status = AudioOutputUnitStop(_audioUnit);
        _playing = !(status == noErr);
        if (_playing) {
            NSLog(@"Cannot stop to play audio");
        }
    }
}

- (OSStatus)render:(AudioBufferList *)ioData count:(UInt32)inNumberFrames {
    UInt32 num = ioData->mNumberBuffers;
    for (UInt32 i = 0; i < num; ++i) {
        AudioBuffer buf = ioData->mBuffers[i];
        memset(buf.mData, 0, buf.mDataByteSize);
    }
    
    if (!_playing || _frameReaderBlock == nil) return noErr;
    
    _frameReaderBlock(_audioData, inNumberFrames, _channelsPerFrame);
    
    if (_bitsPerChannel == 32) {
        float scalar = 0;
        for (UInt32 i = 0; i < num; ++i) {
            AudioBuffer buf = ioData->mBuffers[i];
            UInt32 channels = buf.mNumberChannels;
            for (UInt32 j = 0; j < channels; ++j) {
                vDSP_vsadd(_audioData + i + j, _channelsPerFrame, &scalar, (float *)buf.mData + j, channels, inNumberFrames);
            }
        }
    } else if (_bitsPerChannel == 16) {
        float scalar = INT16_MAX;
        vDSP_vsmul(_audioData, 1, &scalar, _audioData, 1, inNumberFrames * _channelsPerFrame);
        for (UInt32 i = 0; i < num; ++i) {
            AudioBuffer buf = ioData->mBuffers[i];
            UInt32 channels = buf.mNumberChannels;
            for (UInt32 j = 0; j < channels; ++j) {
                vDSP_vfix16(_audioData + i + j, _channelsPerFrame, (short *)buf.mData + j, channels, inNumberFrames);
            }
        }
    }
    
    return noErr;
}

- (double)sampleRate {
    return _sampleRate;
}

- (UInt32)channels {
    return _channelsPerFrame;
}

#pragma mark - Notifications
- (void)registerNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(notifyAudioSessionRouteChanged:)
               name:AVAudioSessionRouteChangeNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(notifyAudioSessionInterruptionNotification:)
               name:AVAudioSessionInterruptionNotification
             object:nil];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session addObserver:self
              forKeyPath:@"outputVolume"
                 options:0
                 context:nil];
}

- (void)unregisterNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session removeObserver:self forKeyPath:@"outputVolume"];
}

- (void)notifyAudioSessionRouteChanged:(NSNotification *)notif {
    [self close];
    [self open:nil];
    [self play];
}

- (void)notifyAudioSessionInterruptionNotification:(NSNotification *)notif {
    AVAudioSessionInterruptionType type = [notif.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        _shouldPlayAfterInterruption = _playing;
        [self pause];
    } else if (type == AVAudioSessionInterruptionTypeEnded) {
        if (_shouldPlayAfterInterruption) {
            _shouldPlayAfterInterruption = NO;
            [self play];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (object == session && [keyPath isEqualToString:@"outputVolume"]) {
        self.volume = session.outputVolume;
    }
}

@end

static OSStatus audioUnitRenderCallback(void *inRefCon,
                                        AudioUnitRenderActionFlags *ioActionFlags,
                                        const AudioTimeStamp *inTimeStamp,
                                        UInt32 inBusNumber,
                                        UInt32 inNumberFrames,
                                        AudioBufferList *ioData) {
    DLGPlayerAudioManager *manager = (__bridge DLGPlayerAudioManager *)(inRefCon);
    return [manager render:ioData count:inNumberFrames];
}
