#import <Foundation/Foundation.h>
#import "HTTPConnection.h"

@class MultipartFormDataParser;

#define HttpUploadNotificationRefreshFileList @"HttpUploadNotificationRefreshFileList"

@interface HTTPUploader : HTTPConnection  {
    MultipartFormDataParser*        parser;
	NSFileHandle*					storeFile;
}

@end
