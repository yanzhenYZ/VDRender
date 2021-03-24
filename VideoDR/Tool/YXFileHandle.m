//
//  YXFileHandle.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import "YXFileHandle.h"

@interface YXFileHandle ()
@property (nonatomic, strong) NSFileHandle *fileHandle;
@end

@implementation YXFileHandle
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *path = [NSHomeDirectory() stringByAppendingString:@"/Documents/test.h264"];
        NSFileManager *manager = NSFileManager.defaultManager;
        if ([manager fileExistsAtPath:path]) {
            [manager removeItemAtPath:path error:nil];
        }
        [manager createFileAtPath:path contents:nil attributes:nil];
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        NSLog(@"____%@:%@", path, _fileHandle);
    }
    return self;
}

- (void)writeData:(NSData *)data {
    [_fileHandle writeData:data];
}

- (void)stop {
    [_fileHandle synchronizeFile];
    [_fileHandle closeFile];
    _fileHandle = nil;
}
@end
