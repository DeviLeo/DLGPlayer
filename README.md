# DLGPlayer
A media player for iOS based on FFmpeg 3.2.2.  
DLGPlayer uses [kolyvan/kxmovie](https://github.com/kolyvan/kxmovie "https://github.com/kolyvan/kxmovie") as reference when written.  
Great thanks for Konstantin Boukreev's kxmovie.  

### 1. Build FFmpeg for iOS
#### (1) Download FFmpeg source from [FFmpeg official site](http://ffmpeg.org/download.html "http://ffmpeg.org/download.html").  
Download and unzip ffmpeg-3.2.2.tar.bz2  

#### (2) Use [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script") to build FFmpeg for iOS  
Follow the steps in the README.md of  kewlbear/FFmpeg-iOS-build-script to build FFmpeg for iOS.  

#### (3) Put built FFmpeg include files and libraries into DLGPlayer/External/ffmpeg folder.  

### 2. Prepare media
#### (1) Put any media files such as mp4 or mp3 into your server's folder.  
Make sure those media files can be access by url (such as http://192.168.31.120/media.mp4) from browser.  

#### (2) Modify code
Open DLGPlayer/ViewController.m and change the \_tfUrl.text value to your media file's url.

### 3. Run demo
Build project and run demo on your device or simulator.  

### 4. Usage
#### (1) You can use DLGPlayerViewController to play media file with HUD.
```Objective-C
    DLGPlayerViewController *vc = [[DLGPlayerViewController alloc] init];
    vc.autoplay = YES;
    vc.repeat = YES;
    vc.preventFromScreenLock = YES;
    vc.restorePlayAfterAppEnterForeground = YES;
    vc.view.translatesAutoresizingMaskIntoConstraints = YES;
    vc.view.frame = self.view.frame;
    [self.view addSubview:vc.view];
    vc.url = @"http://192.168.31.120/media.mp4";
    [vc open];
```

#### (2) You can use DLGPlayer to play media file without HUD.
```Objective-C
    DLGPlayer *player = [[DLGPlayer alloc] init];
    UIView *v = player.playerView;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.frame = self.view.frame;
    [self.view addSubview:v];
    [player open:@"http://192.168.31.120/media.mp4"];
    [player play];
```
See DLGPlayerViewController for more details.  

### 5. Required frameworks and libraries
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

### 6. References
* [kolyvan/kxmovie](https://github.com/kolyvan/kxmovie "https://github.com/kolyvan/kxmovie")
* [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script")
* [libav/gas-preprocessor](https://github.com/libav/gas-preprocessor "https://github.com/libav/gas-preprocessor")
* [FFmpeg](http://ffmpeg.org "http://ffmpeg.org")
* [Yasm](http://yasm.tortall.net "http://yasm.tortall.net")
