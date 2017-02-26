# DLGPlayer
A media player for iOS based on FFmpeg 3.2.2.  
DLGPlayer uses [kolyvan/kxmovie](https://github.com/kolyvan/kxmovie "https://github.com/kolyvan/kxmovie") as reference when written.  
Great thanks for Konstantin Boukreev's kxmovie.  

## 0. Screenshots
|Orientation|Audio|Video|
|:---------:|:---:|:---:|
|Portrait|![](https://github.com/DeviLeo/Screenshots/blob/master/DLGPlayer/Simulator%20Screen%20Shot%2022%20Dec%202016%2C%202.00.52%20PM.png)|![](https://github.com/DeviLeo/Screenshots/blob/master/DLGPlayer/Simulator%20Screen%20Shot%2022%20Dec%202016%2C%202.07.30%20PM.png)|
|Landscape|![](https://github.com/DeviLeo/Screenshots/blob/master/DLGPlayer/Simulator%20Screen%20Shot%2022%20Dec%202016%2C%202.01.05%20PM.png)|![](https://github.com/DeviLeo/Screenshots/blob/master/DLGPlayer/Simulator%20Screen%20Shot%2022%20Dec%202016%2C%202.07.38%20PM.png)|

## 1. Build FFmpeg for iOS
#### (1) Download FFmpeg source from [FFmpeg official site](http://ffmpeg.org/download.html "http://ffmpeg.org/download.html").  
Download and unzip ffmpeg-3.2.2.tar.bz2  

#### (2) Use [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script") to build FFmpeg for iOS  
Follow the steps in the [README.md](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script") of [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script") to build FFmpeg for iOS.  

#### (3) Put built FFmpeg include files and libraries into DLGPlayer/Externals/ffmpeg folder.  
Put built "ffmpeg/include" and "ffmpeg/lib" folders into example project's "DLGPlayer/Externals/ffmpeg" folder.  

## 2. Prepare media
#### (1) Put any media files such as mp4 or mp3 into your server's folder.  
Make sure those media files can be access by url (such as http://192.168.31.120/media.mp4) from browser.  

#### (2) Modify code
Open **DLGPlayer/ViewController.m** and change the **\_tfUrl.text** value to your media file's url.

## 3. Run demo
Build project and run demo on your device or simulator.  

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

Thank you all!

## 7. License
See [LICENSE](https://github.com/DeviLeo/DLGPlayer/blob/master/LICENSE "LGPL-3.0").
