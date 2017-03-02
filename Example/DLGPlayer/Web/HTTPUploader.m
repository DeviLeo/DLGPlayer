#import "HTTPUploader.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "DDNumber.h"
#import "HTTPLogging.h"

#import "MultipartFormDataParser.h"
#import "MultipartMessageHeaderField.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPFileResponse.h"

// Log levels : off, error, warn, info, verbose
// Other flags: trace

#ifdef DEBUG
static const int httpLogLevel = HTTP_LOG_LEVEL_VERBOSE; // | HTTP_LOG_FLAG_TRACE;
#else
static const int httpLogLevel = HTTP_LOG_LEVEL_OFF;
#endif


/**
 * All we have to do is override appropriate methods in HTTPConnection.
 **/

@implementation HTTPUploader

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Add support for POST
	
	if ([method isEqualToString:@"POST"])
	{
		if ([path isEqualToString:@"/"] ||
            [path isEqualToString:@"/upload"])
		{
			return YES;
		}
	}
	
	return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
    
    HTTPLogVerbose(@">>> expectsRequestBodyFromMethod: %@ atPath: %@", method, path);
	
	// Inform HTTP server that we expect a body to accompany a POST request
    
	if([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload"]) {
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if( NSNotFound == paramsSeparator ) {
            return NO;
        }
        if( paramsSeparator >= contentType.length - 1 ) {
            return NO;
        }
        NSString* type = [contentType substringToIndex:paramsSeparator];
        if( ![type isEqualToString:@"multipart/form-data"] ) {
            // we expect multipart/form-data content type
            return NO;
        }

		// enumerate all params in content-type, and find boundary there
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for( NSString* param in params ) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if( (NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1 ) {
                continue;
            }
            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];
            
            if( [paramName isEqualToString: @"boundary"] ) {
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
            }
        }
        // check if boundary specified
        if( nil == [request headerField:@"boundary"] )  {
            return NO;
        }
        return YES;
    }
	return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	HTTPLogTrace();
    
    HTTPLogVerbose(@">>> httpResponseForMethod: %@ URI: %@", method, path);
    
    if ([method isEqualToString:@"GET"]) {
        if ([path hasPrefix:@"/check?filename="]) {
            NSString *filename = [[path substringFromIndex:[path rangeOfString:@"="].location+1] stringByRemovingPercentEncoding];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *filePath = [docPath stringByAppendingPathComponent:filename];
            
            NSString *responseText = @"1";
            if ([fm fileExistsAtPath:filePath]) {
                responseText = @"0";
            }
            NSData *data = [responseText dataUsingEncoding:NSUTF8StringEncoding];
            HTTPDataResponse *resp = [[HTTPDataResponse alloc] initWithData:data];
            return resp;
        } else if ([path hasPrefix:@"/deleteAllFiles"]) {
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSArray *files = [fm contentsOfDirectoryAtPath:docPath error:nil];
            for (NSString *filePath in files) {
                NSString *fullPath = [docPath stringByAppendingPathComponent:filePath];
                [fm removeItemAtPath:fullPath error:nil];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:HttpUploadNotificationRefreshFileList object:nil];
            
            NSString *responseText = [NSString stringWithFormat:@"%lu", (unsigned long)files.count];
            NSData *data = [responseText dataUsingEncoding:NSUTF8StringEncoding];
            HTTPDataResponse *resp = [[HTTPDataResponse alloc] initWithData:data];
            return resp;
        } else if ([path hasPrefix:@"/delete?file="]) {
            NSString *filename = [[path substringFromIndex:[path rangeOfString:@"="].location+1] stringByRemovingPercentEncoding];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *filePath = [docPath stringByAppendingPathComponent:filename];
            
            NSString *responseText = @"0";
            if ([fm fileExistsAtPath:filePath]) {
                if ([fm removeItemAtPath:filePath error:nil]) {
                    responseText = @"1";
                }
            } else {
                responseText = @"1";
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:HttpUploadNotificationRefreshFileList object:nil];
            
            NSData *data = [responseText dataUsingEncoding:NSUTF8StringEncoding];
            HTTPDataResponse *resp = [[HTTPDataResponse alloc] initWithData:data];
            return resp;
        }
    }
    
    if ([path isEqualToString:@"/"]) {
		// show all files under documents folder
		NSMutableString* filesStr = [[NSMutableString alloc] init];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSArray *files = [fm contentsOfDirectoryAtPath:docPath error:nil];
        int index = 0;
        for (NSString *filePath in files) {
            NSString *fullPath = [docPath stringByAppendingPathComponent:filePath];
            NSString *filename = [filePath lastPathComponent];
            // Get file's size
            NSDictionary *attr = [fm attributesOfItemAtPath:fullPath error:nil];
            long long size = [[attr objectForKey:NSFileSize] longLongValue];
            float fSize = 0.0f;
            int level = 0;
            while (size > 1024) {
                level++;
                fSize = size / 1024.00f;
                size /= 1024;
                if (level >= 5) break;
            }
            NSString *fileSize= nil;
            if (level == 0) { fileSize = [NSString stringWithFormat:@"%lldB", size]; }
            else if (level == 1) { fileSize = [NSString stringWithFormat:@"%.2fK", fSize]; }
            else if (level == 2) { fileSize = [NSString stringWithFormat:@"%.2fM", fSize]; }
            else if (level == 3) { fileSize = [NSString stringWithFormat:@"%.2fG", fSize]; }
            else if (level == 4) { fileSize = [NSString stringWithFormat:@"%.2fT", fSize]; }
            else if (level == 5) { fileSize = [NSString stringWithFormat:@"%.2fP", fSize]; }
            // <tr id="uploaded_tr_%d" style="border-bottom-style:solid;border-bottom-color:#EEEEEE;border-bottom-width:1px;" onclick="onRowClick(this)">
            //   <td class="uploaded_tr_0"><input id="uploaded_checkbox_%d" type="checkbox" value="%@" onchange="onRowCheckboxClick(this)"/></td>
            //   <td class="uploaded_tr_1"><a href=\"%@\">%@</a></td>
            //   <td class="uploaded_tr_2">%@</td>
            // </tr>
            [filesStr appendFormat:@"<tr id=\"uploaded_tr_%d\" style=\"border-bottom-style:solid;border-bottom-color:#EEEEEE;border-bottom-width:1px;\" onclick=\"onRowClick(this)\">", index];
            [filesStr appendFormat:@"<td class=\"uploaded_tr_0\"><input id=\"uploaded_checkbox_%d\" type=\"checkbox\" value=\"%@\" onchange=\"onRowCheckboxClick(this)\"/></td>", index, filename];
            [filesStr appendFormat:@"<td class=\"uploaded_tr_1\"><a href=\"%@\" target=\"_blank\">%@</a></td>", filePath, filename];
            [filesStr appendFormat:@"<td class=\"uploaded_tr_2\">%@</td>", fileSize];
            [filesStr appendString:@"</tr>"];
            ++index;
        }
		NSString* templatePath = [[config documentRoot] stringByAppendingPathComponent:@"index.html"];
		NSDictionary* replacementDict = [NSDictionary dictionaryWithObject:filesStr forKey:@"MyFiles"];
		return [[HTTPDynamicFileResponse alloc] initWithFilePath:templatePath forConnection:self separator:@"%" replacementDictionary:replacementDict];
    }
    
    // download
    NSString *filename = [[path lastPathComponent] stringByRemovingPercentEncoding];
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:filename];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:filePath isDirectory:&isDir]) {
        if (!isDir) {
            return [[HTTPFileResponse alloc] initWithFilePath:filePath forConnection:self];
        }
    }
	
	return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	HTTPLogTrace();
	
	// set up mime parser
    NSString* boundary = [request headerField:@"boundary"];
    parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    parser.delegate = self;
}

- (void)processBodyData:(NSData *)postDataChunk
{
	HTTPLogTrace();
    // append data to the parser. It will invoke callbacks to let us handle
    // parsed data.
    [parser appendData:postDataChunk];
}


//-----------------------------------------------------------------
#pragma mark multipart form data parser delegate


- (void) processStartOfPartWithHeader:(MultipartMessageHeader*) header {
	// in this sample, we are not interested in parts, other then file parts.
	// check content disposition to find out filename

    MultipartMessageHeaderField* disposition = [header.fields objectForKey:@"Content-Disposition"];
	NSString* filename = [[disposition.params objectForKey:@"filename"] lastPathComponent];

    if ( (nil == filename) || [filename isEqualToString: @""] ) {
        // it's either not a file part, or
		// an empty form sent. we won't handle it.
		return;
	}
    
//	NSString* uploadDirPath = [[config documentRoot] stringByAppendingPathComponent:@"upload"];
    NSString *uploadDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

	BOOL isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:uploadDirPath isDirectory:&isDir ]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
    NSString* filePath = [uploadDirPath stringByAppendingPathComponent: filename];
    if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
        if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:nil]) {
            storeFile = nil;
            return;
        }
    }
    
    HTTPLogVerbose(@"Saving file to %@", filePath);
    if(![[NSFileManager defaultManager] createDirectoryAtPath:uploadDirPath withIntermediateDirectories:true attributes:nil error:nil]) {
        HTTPLogError(@"Could not create directory at path: %@", filePath);
    }
    if(![[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]) {
        HTTPLogError(@"Could not create file at path: %@", filePath);
    }
    storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
}


- (void) processContent:(NSData*) data WithHeader:(MultipartMessageHeader*) header 
{
	// here we just write the output from parser to the file.
	if( storeFile ) {
		[storeFile writeData:data];
	}
}

- (void) processEndOfPartWithHeader:(MultipartMessageHeader*) header
{
	// as the file part is over, we close the file.
	[storeFile closeFile];
	storeFile = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HttpUploadNotificationRefreshFileList object:nil];
}

- (void) processPreambleData:(NSData*) data
{
    // if we are interested in preamble data, we could process it here.

}

- (void) processEpilogueData:(NSData*) data 
{
    // if we are interested in epilogue data, we could process it here.

}

@end
