## 1. Download OpenSSL source from [OpenSSL official site](https://www.openssl.org "https://www.openssl.org")
Download openssl-1.0.2o.tar.gz  
**DO NOT** use OpenSSL 1.1.0, because FFmpeg 4.0 is not compatible for now.  

## 2. Use [x2on/OpenSSL-for-iPhone](https://github.com/x2on/OpenSSL-for-iPhone "https://github.com/x2on/OpenSSL-for-iPhone") to build OpenSSL for iOS
Follow the steps in the [README.md](https://github.com/x2on/OpenSSL-for-iPhone "https://github.com/x2on/OpenSSL-for-iPhone") of [x2on/OpenSSL-for-iPhone](https://github.com/x2on/OpenSSL-for-iPhone "https://github.com/x2on/OpenSSL-for-iPhone") to build OpenSSL for iOS.  
You need to edit __build-libssl.sh__ since the default version may be others.  
```
# Change default version to 1.0.2o
DEFAULTVERSION="1.0.2o"
```

## 3. Copy built OpenSSL include files and libraries into a temporary folder
After built successfully, you will find "include" and "lib" folders.  
Copy them into a temporary folder, and you can name it to "openssl".  

## 4. Edit build-ffmpeg.sh file
#### (1) Download [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script")
Download [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script") and you will see the **"FFmpeg-iOS-build-script"** folder.  

#### (2) Duplicate "build-ffmpeg.sh"
Make a copy of **"build-ffmpeg.sh"** and rename it to **"build-ffmpeg-openssl.sh"**.  

#### (3) Edit "build-ffmpeg-openssl.sh"
Add the scripts between **##### Add Begin #####** and **#####  Add End  #####** to build with OpenSSL:  
```bash

...

##### Change Begin #####
FF_VERSION="4.0"
#####  Change End  #####

...

#FDK_AAC=`pwd`/../fdk-aac-build-script-for-iOS/fdk-aac-ios

##### Add Begin #####
# OpenSSL
OPENSSL=`pwd`/openssl
#####  Add End  #####

CONFIGURE_FLAGS="--enable-cross-compile --disable-debug --disable-programs \
                 --disable-doc --enable-pic"

...

if [ "$FDK_AAC" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac"
fi

##### Add Begin #####
if [ "$OPENSSL" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-openssl"
fi
#####  Add End  #####

# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"

...

if [ "$FDK_AAC" ]
then
	CFLAGS="$CFLAGS -I$FDK_AAC/include"
	LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
fi

##### Add Begin #####
if [ "$OPENSSL" ]
then
	CFLAGS="$CFLAGS -I$OPENSSL/include"
	LDFLAGS="$LDFLAGS -L$OPENSSL/lib"
fi
#####  Add End  #####

TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \

...

```

## 5. Move "openssl" folder into "FFmpeg-iOS-build-script" folder
Move the **"openssl"** folder into the **"FFmpeg-iOS-build-script"** folder.  
Make sure the **"build-ffmpeg-openssl.sh"** file is under the **"FFmpeg-iOS-build-script"** folder, too.  

## 6. Edit "audio_convert_neon.S"  
This step is especially for __FFmpeg 4.0 (armv7/armv7s)__.  
If you are about to compile __FFmpeg 4.0 (arm64/i386/x86_64)__ or __lower (armv7/armv7s/arm64/i386/x86_64)__, you can skip this step.  
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

## 7. Run "build-ffmpeg-openssl.sh"
Run and wait.  

## 8. Put built FFmpeg include files and libraries into "DLGPlayer/Externals/ffmpeg" folder
Put built **"ffmpeg/include"** and **"ffmpeg/lib"** folders into the example project's **"DLGPlayer/Externals/ffmpeg"** folder.  

## 9. Add OpenSSL into the example project
Put **"openssl"** folder into the example project's **"DLGPlayer/Externals"** folder.  
In Xcode, right click **"Externals"** folder, choose **"Add Files to ..."**, select **"openssl"** folder and click **"Add"** button.  

## 10. Run the demo
Build the example project and run the demo on your device or simulator.  
