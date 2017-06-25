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
    BOOL _registeredKVO;
    BOOL _opened;
    BOOL _closing;
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
    _registeredKVO = NO;
    _opened = NO;
    _closing = NO;
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
    NSLog(@"DLGPlayerAudioManager dealloc");
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
    
    NSError *rawError = nil;
    if (![session setCategory:AVAudioSessionCategoryPlayback error:&rawError]) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeCannotSetAudioCategory
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_SET_AUDIO_CATEGORY"]
                        andRawError:rawError];
        return NO;
    }
    
    NSTimeInterval prefferedIOBufferDuration = PREFERRED_BUFFER_DURATION;
    if (![session setPreferredIOBufferDuration:prefferedIOBufferDuration error:&rawError]) {
        NSLog(@"setPreferredIOBufferDuration: %.4f, error: %@", prefferedIOBufferDuration, rawError);
    }
    
    double prefferedSampleRate = PREFERRED_SAMPLE_RATE;
    if (![session setPreferredSampleRate:prefferedSampleRate error:&rawError]) {
        NSLog(@"setPreferredSampleRate: %.4f, error: %@", prefferedSampleRate, rawError);
    }
    
    if (![session setActive:YES error:&rawError]) {
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeCannotSetAudioActive
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_SET_AUDIO_ACTIVE"]
                        andRawError:rawError];
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
    
    [self registerNotifications];
    _sampleRate = sampleRate;
    _volume = volume;
    _opened = YES;
    
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
        NSError *rawError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeCannotCreateAudioComponent
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_CREATE_AUDIO_UNIT"]
                        andRawError:rawError];
        return NO;
    }
    
    AudioStreamBasicDescription streamDescr = {0};
    UInt32 size = sizeof(AudioStreamBasicDescription);
    status = AudioUnitGetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input,
                                  0, &streamDescr, &size);
    if (status != noErr) {
        NSError *rawError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeCannotGetAudioStreamDescription
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_GET_AUDIO_STREAM_DESCRIPTION"]
                        andRawError:rawError];
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
        NSError *rawError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeCannotSetAudioRenderCallback
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_SET_AUDIO_RENDER_CALLBACK"]
                        andRawError:rawError];
        return NO;
    }
    
    status = AudioUnitInitialize(audioUnit);
    if (status != noErr) {
        NSError *rawError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        [DLGPlayerUtils createError:error
                         withDomain:DLGPlayerErrorDomainAudioManager
                            andCode:DLGPlayerErrorCodeCannotInitAudioUnit
                         andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_INIT_AUDIO_UNIT"]
                        andRawError:rawError];
        return NO;
    }
    
    _audioUnit = audioUnit;
    
    return YES;
}

- (BOOL)close {
    return [self close:nil];
}

- (BOOL)close:(NSArray<NSError *> **)errors {
    if (_closing) return NO;
    _closing = YES;
    
    NSMutableArray<NSError *> *errs = nil;
    if (errors != nil) errs = [NSMutableArray array];
    
    BOOL closed = YES;
    
    if (_opened) {
        [self pause];
        
        [self unregisterNotifications];
        
        OSStatus status = AudioUnitUninitialize(_audioUnit);
        if (status != noErr) {
            closed = NO;
            if (errs != nil) {
                NSError *error = nil;
                NSError *rawError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
                [DLGPlayerUtils createError:&error
                                 withDomain:DLGPlayerErrorDomainAudioManager
                                    andCode:DLGPlayerErrorCodeCannotUninitAudioUnit
                                 andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_UNINIT_AUDIO_UNIT"]
                                andRawError:rawError];
                [errs addObject:error];
            }
        }
        
        status = AudioComponentInstanceDispose(_audioUnit);
        if (status != noErr) {
            closed = NO;
            if (errs != nil) {
                NSError *error = nil;
                NSError *rawError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
                [DLGPlayerUtils createError:&error
                                 withDomain:DLGPlayerErrorDomainAudioManager
                                    andCode:DLGPlayerErrorCodeCannotDisposeAudioUnit
                                 andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_DISPOSE_AUDIO_UNIT"]
                                andRawError:rawError];
                [errs addObject:error];
            }
        }
        
        NSError *error = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        if (![session setActive:NO error:&error]) {
            closed = NO;
            if (errs != nil) {
                NSError *error = nil;
                NSError *rawError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
                [DLGPlayerUtils createError:&error
                                 withDomain:DLGPlayerErrorDomainAudioManager
                                    andCode:DLGPlayerErrorCodeCannotDeactivateAudio
                                 andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_DEACTIVATE_AUDIO"]
                                andRawError:rawError];
                [errs addObject:error];
            }
        }
        
        if (closed) _opened = NO;
    }
    
    _closing = NO;
    
    return closed;
}

- (BOOL)play {
    return [self play:nil];
}

- (BOOL)play:(NSError **)error {
    if (_opened) {
        OSStatus status = AudioOutputUnitStart(_audioUnit);
        _playing = (status == noErr);
        if (!_playing) {
            NSError *rawError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            [DLGPlayerUtils createError:error
                             withDomain:DLGPlayerErrorDomainAudioManager
                                andCode:DLGPlayerErrorCodeCannotStartAudioUnit
                             andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_START_AUDIO_UNIT"]
                            andRawError:rawError];
        }
    }
    return _playing;
}

- (BOOL)pause {
    return [self pause:nil];
}

- (BOOL)pause:(NSError **)error {
    if (_playing) {
        OSStatus status = AudioOutputUnitStop(_audioUnit);
        _playing = !(status == noErr);
        if (_playing) {
            NSError *rawError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            [DLGPlayerUtils createError:error
                             withDomain:DLGPlayerErrorDomainAudioManager
                                andCode:DLGPlayerErrorCodeCannotStopAudioUnit
                             andMessage:[DLGPlayerUtils localizedString:@"DLG_PLAYER_STRINGS_CANNOT_STOP_AUDIO_UNIT"]
                            andRawError:rawError];
        }
    }
    return !_playing;
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
    
    if (!_registeredKVO) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session addObserver:self
                  forKeyPath:@"outputVolume"
                     options:0
                     context:nil];
        _registeredKVO = YES;
    }
}

- (void)unregisterNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    if (_registeredKVO) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session removeObserver:self forKeyPath:@"outputVolume"];
        _registeredKVO = NO;
    }
}

- (void)notifyAudioSessionRouteChanged:(NSNotification *)notif {
    if ([self close]) {
        if ([self open:nil]) {
            [self play];
        }
    }
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
