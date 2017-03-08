//
//  DLGPlayerDef.h
//  DLGPlayer
//
//  Created by Liu Junqi on 05/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#ifndef DLGPlayerDef_h
#define DLGPlayerDef_h

#define DLGPlayerLocalizedStringTable   @"DLGPlayerStrings"

#define DLGPlayerMinBufferDuration  2
#define DLGPlayerMaxBufferDuration  5

#define DLGPlayerErrorDomainDecoder         @"DLGPlayerDecoder"
#define DLGPlayerErrorDomainAudioManager    @"DLGPlayerAudioManager"

#define DLGPlayerErrorCodeInvalidURL                        -1
#define DLGPlayerErrorCodeCannotOpenInput                   -2
#define DLGPlayerErrorCodeCannotFindStreamInfo              -3
#define DLGPlayerErrorCodeNoVideoAndAudioStream             -4

#define DLGPlayerErrorCodeNoAudioOuput                      -5
#define DLGPlayerErrorCodeNoAudioChannel                    -6
#define DLGPlayerErrorCodeNoAudioSampleRate                 -7
#define DLGPlayerErrorCodeNoAudioVolume                     -8
#define DLGPlayerErrorCodeCannotSetAudioCategory            -9
#define DLGPlayerErrorCodeCannotSetAudioActive              -10
#define DLGPlayerErrorCodeCannotInitAudioUnit               -11
#define DLGPlayerErrorCodeCannotCreateAudioComponent        -12
#define DLGPlayerErrorCodeCannotGetAudioStreamDescription   -13
#define DLGPlayerErrorCodeCannotSetAudioRenderCallback      -14
#define DLGPlayerErrorCodeCannotUninitAudioUnit             -15
#define DLGPlayerErrorCodeCannotDisposeAudioUnit            -16
#define DLGPlayerErrorCodeCannotDeactivateAudio             -17
#define DLGPlayerErrorCodeCannotStartAudioUnit              -18
#define DLGPlayerErrorCodeCannotStopAudioUnit               -19

#pragma mark - Notification
#define DLGPlayerNotificationOpened                 @"DLGPlayerNotificationOpened"
#define DLGPlayerNotificationClosed                 @"DLGPlayerNotificationClosed"
#define DLGPlayerNotificationEOF                    @"DLGPlayerNotificationEOF"
#define DLGPlayerNotificationBufferStateChanged     @"DLGPlayerNotificationBufferStateChanged"
#define DLGPlayerNotificationError                  @"DLGPlayerNotificationError"

#pragma mark - Notification Key
#define DLGPlayerNotificationBufferStateKey         @"DLGPlayerNotificationBufferStateKey"
#define DLGPlayerNotificationSeekStateKey           @"DLGPlayerNotificationSeekStateKey"
#define DLGPlayerNotificationErrorKey               @"DLGPlayerNotificationErrorKey"
#define DLGPlayerNotificationRawErrorKey            @"DLGPlayerNotificationRawErrorKey"

#endif /* DLGPlayerDef_h */
