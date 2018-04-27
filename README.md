# DLGPlayer
A media player for iOS based on FFmpeg 4.0.  
DLGPlayer uses [kolyvan/kxmovie](https://github.com/kolyvan/kxmovie "https://github.com/kolyvan/kxmovie") as reference when written and **NO deprecated** functions and methods are used.  
If you found any deprecated function or method, please submit an issue to me.  
Great thanks for Konstantin Boukreev's kxmovie.  

## 0. Screenshots
|Orientation|Audio|Video|
|:---------:|:---:|:---:|
|Portrait|![](https://github.com/DeviLeo/Screenshots/blob/master/DLGPlayer/Simulator%20Screen%20Shot%2022%20Dec%202016%2C%202.00.52%20PM.png)|![](https://github.com/DeviLeo/Screenshots/blob/master/DLGPlayer/Simulator%20Screen%20Shot%2022%20Dec%202016%2C%202.07.30%20PM.png)|
|Landscape|![](https://github.com/DeviLeo/Screenshots/blob/master/DLGPlayer/Simulator%20Screen%20Shot%2022%20Dec%202016%2C%202.01.05%20PM.png)|![](https://github.com/DeviLeo/Screenshots/blob/master/DLGPlayer/Simulator%20Screen%20Shot%2022%20Dec%202016%2C%202.07.38%20PM.png)|

## 1. Build FFmpeg for iOS
#### (0) Support https (Optional)  
If you want to build FFmpeg with OpenSSL to support https, please see [How to build FFmpeg with OpenSSL](How_to_build_ffmpeg_with_openssl.md "How_to_build_ffmpeg_with_openssl.md") first, or continue.  

#### (1) Download FFmpeg source from [FFmpeg official site](http://ffmpeg.org/download.html "http://ffmpeg.org/download.html").  
Download and unzip ffmpeg-4.0.tar.bz2  

#### (2) Use [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script") to build FFmpeg for iOS  
Follow the steps in the [README.md](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script") of [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script") to build FFmpeg for iOS.  
You need to edit __build-ffmpeg.sh__ since the default version may not be 4.0.
```
##### Change Begin #####
FF_VERSION="4.0"
#####  Change End  #####
```

You need to edit __audio_convert_neon.S__ if you are about to compile __FFmpeg 4.0 (armv7/armv7s)__.  
Open the file "__ffmpeg-4.0/libswresample/arm/audio_convert_neon.S__".  

Delete `_swri_oldapi_conv_flt_to_s16_neon:` and `_swri_oldapi_conv_fltp_to_s16_2ch_neon:`.  
Change `_swri_oldapi_conv_flt_to_s16_neon` to `X(swri_oldapi_conv_flt_to_s16_neon)` and `_swri_oldapi_conv_fltp_to_s16_2ch_neon` to `X(swri_oldapi_conv_fltp_to_s16_2ch_neon)`.  

```
...

function swri_oldapi_conv_flt_to_s16_neon, export=1
// >> Delete Begin
// _swri_oldapi_conv_flt_to_s16_neon:
// << Delete End
        subs            r2,  r2,  #8
        vld1.32         {q0},     [r1,:128]!
        vcvt.s32.f32    q8,  q0,  #31

...

function swri_oldapi_conv_fltp_to_s16_2ch_neon, export=1
// >> Delete Begin
// _swri_oldapi_conv_fltp_to_s16_2ch_neon:
// << Delete End
        ldm             r1,  {r1, r3}
        subs            r2,  r2,  #8
        vld1.32         {q0},     [r1,:128]!

...

function swri_oldapi_conv_fltp_to_s16_nch_neon, export=1
        cmp             r3,  #2
        itt             lt
        ldrlt           r1,  [r1]
// >> Change Begin
//        blt             _swri_oldapi_conv_flt_to_s16_neon
//        beq             _swri_oldapi_conv_fltp_to_s16_2ch_neon
        blt             X(swri_oldapi_conv_flt_to_s16_neon)
        beq             X(swri_oldapi_conv_fltp_to_s16_2ch_neon)
// << Change End

        push            {r4-r8, lr}
        cmp             r3,  #4
        lsl             r12, r3,  #1
        blt             4f

...

```

#### (3) Put built FFmpeg include files and libraries into DLGPlayer/Externals/ffmpeg folder.  
Put built "ffmpeg/include" and "ffmpeg/lib" folders into example project's "DLGPlayer/Externals/ffmpeg" folder.  

## 2. Run demo
Build project and run demo on your device or simulator.  

## 3. Play media
#### (1) Put any media files such as mp4 or mp3 into your server's folder.  
Make sure those media files can be access by url (such as http://192.168.31.120/media.mp4) from browser.  
Then input "http://192.168.31.120/media.mp4" into the text box on the top of the main view and go!

#### (2) Transfer any media files using file management.
Select "Local Files" in the main view.  
Transfer the media files according to the tips on the top of the file management view.  
Select any one media file listed in the table and enjoy it!  

## 4. Usage
#### (1) Use *DLGPlayerViewController* to play a media file with HUD.
```Objective-C
    DLGPlayerViewController *vc = [[DLGPlayerViewController alloc] init];
    vc.autoplay = YES;
    vc.repeat = YES;
    vc.preventFromScreenLock = YES;
    vc.restorePlayAfterAppEnterForeground = YES;
    vc.view.frame = self.view.frame;
    [self.view addSubview:vc.view];
    vc.url = @"http://192.168.31.120/media.mp4";
    [vc open];
```

#### (2) Use *DLGPlayer* to play a media file without HUD.
```Objective-C
    DLGPlayer *player = [[DLGPlayer alloc] init];
    UIView *v = player.playerView;
    v.frame = self.view.frame;
    [self.view addSubview:v];
    [player open:@"http://192.168.31.120/media.mp4"];
    [player play];
```
See ***DLGPlayerViewController*** class for more usage details.

## 5. Required frameworks and libraries
* Accelerate.framework
* AudioToolbox.framework
* CoreAudio.framework
* CoreGraphics.framework
* CoreMedia.framework
* MediaPlayer.framework
* OpenGLES.framework
* QuartzCore.framework
* VideoToolbox.framework
* libiconv.tbd
* libbz2.tbd
* libz.tbd

## 6. References
* [FFmpeg](http://ffmpeg.org "http://ffmpeg.org")
* [kolyvan/kxmovie](https://github.com/kolyvan/kxmovie "https://github.com/kolyvan/kxmovie")
* [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script")
* [libav/gas-preprocessor](https://github.com/libav/gas-preprocessor "https://github.com/libav/gas-preprocessor")
* [Yasm](http://yasm.tortall.net "http://yasm.tortall.net")
* [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket "https://github.com/robbiehanson/CocoaAsyncSocket")
* [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer "https://github.com/robbiehanson/CocoaHTTPServer")
* [OpenSSL](https://www.openssl.org "https://www.openssl.org")
* [x2on/OpenSSL-for-iPhone](https://github.com/x2on/OpenSSL-for-iPhone "https://github.com/x2on/OpenSSL-for-iPhone")

Thank you all!

## 7. License
See [LICENSE](https://github.com/DeviLeo/DLGPlayer/blob/master/LICENSE "LGPL-3.0").
