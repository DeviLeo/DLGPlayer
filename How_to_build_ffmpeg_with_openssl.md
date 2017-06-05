## 1. Download OpenSSL source from [OpenSSL official site](https://www.openssl.org "https://www.openssl.org")
Download openssl-1.0.2l.tar.gz  
*DO NOT* use OpenSSL 1.1.0, because FFmpeg 3.3.1 does not support it for now.  

## 2. Use [x2on/OpenSSL-for-iPhone](https://github.com/x2on/OpenSSL-for-iPhone "https://github.com/x2on/OpenSSL-for-iPhone") to build OpenSSL for iOS  
Follow the steps in the [README.md](https://github.com/x2on/OpenSSL-for-iPhone "https://github.com/x2on/OpenSSL-for-iPhone") of [x2on/OpenSSL-for-iPhone](https://github.com/x2on/OpenSSL-for-iPhone "https://github.com/x2on/OpenSSL-for-iPhone") to build OpenSSL for iOS.  

## 3. Copy built OpenSSL include files and libraries into a temporary folder
After built successfully, you will find "include" and "lib" folders.  
Copy them into a temporary folder, you can name it to "openssl".  

## 4. Edit build-ffmpeg.sh file
#### (1) Download  [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script "https://github.com/kewlbear/FFmpeg-iOS-build-script")  

#### (2) Duplicate "build-ffmpeg.sh"  
Make a copy of build-ffmpeg.sh and rename it to "build-ffmpeg-openssl.sh".  

#### (3) Edit "build-ffmpeg-openssl.sh"  
Add OpenSSL scripts:
```bash

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

## 6. Run "build-ffmpeg-openssl.sh"

## 7. Put built FFmpeg include files and libraries into DLGPlayer/Externals/ffmpeg folder
Put built "ffmpeg/include" and "ffmpeg/lib" folders into example project's "DLGPlayer/Externals/ffmpeg" folder.  

## 8. Add OpenSSL into example project
Put "openssl" folder into example project's "DLGPlayer/Externals/ffmpeg" folder.   
In Xcode, right click "Externals" folder, choose "Add Files to ...", select "openssl" folder and click "Add" button.  

## 9. Build and Run