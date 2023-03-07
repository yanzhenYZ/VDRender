//
//  H264FileParser.m
//  VideoDR
//
//  Created by yanzhen on 2023/3/7.
//

#import "H264FileParser.h"

@interface H264FileParser ()
@property (nonatomic, copy) NSString *file;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableData *h264Data;

@property (nonatomic) int frameCount;
@end

@implementation H264FileParser {
    dispatch_queue_t _queue;
}
- (instancetype)initWithFile:(NSString *)file {
    self = [super init];
    if (self) {
        _file = file;
        _h264Data = [NSMutableData dataWithContentsOfFile:file];
        _queue = dispatch_queue_create("cn.h264.test", NULL);
    }
    return self;
}

- (void)startWithTimeInterval:(NSTimeInterval)interval {
    if (_timer) { return; }
    __weak H264FileParser *weakParser = self;
    _timer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakParser parserH264Data];
    }];
}


- (void)parserH264Data {
    dispatch_async(_queue, ^{
        [self getH264Data];
    });
}

//只考虑0x00000001
- (void)getH264Data {
    if (_h264Data.length <= 0) {
        [self stop];
        NSLog(@"done:%d", _frameCount);
        return;
    }
    NSData *data = [self getFrame:_h264Data];
    if (data.length <= 0) { return; }
    [_h264Data replaceBytesInRange:NSMakeRange(0, data.length) withBytes:0 length:0];
    //NSLog(@"%d", bytes[4] & 0x1F);
    //NSLog(@"%d", _h264Data.length);
    //1.h164 total 130 //126->127方向变化
//    if (_frameCount++ > 127) {
//        return;
//    }
    if ([_delegate respondsToSelector:@selector(parser:h264Data:)]) {
        [_delegate parser:self h264Data:data];
    }
}

- (NSData *)getFrame:(NSData *)h264Data {
    NSInteger index =-1;
    char *data = (char *)h264Data.bytes;
    for (int i = 4; i < h264Data.length - 3; i++) {
        if (data[i] == 0x00 && data[i+1] == 0x00 && data[i+2] == 0x00 && data[i+3] == 0x01) {
            index = i;
            break;
        }
    }
    if (index != -1) {
        return [h264Data subdataWithRange:NSMakeRange(0, index)];
        //[_h264Data replaceBytesInRange:NSMakeRange(0, index) withBytes:0 length:0];
    }
    return [h264Data subdataWithRange:NSMakeRange(0, h264Data.length)];
    //return nil;
}

- (void)stop {
    [_timer invalidate];
    _timer = nil;
}

- (void)dealloc {
    [self stop];
    //NSLog(@"h264 parser dealloc");
}
@end