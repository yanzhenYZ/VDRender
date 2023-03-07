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
@property (nonatomic, strong) NSData *h264Data;
@end

@implementation H264FileParser
- (instancetype)initWithFile:(NSString *)file {
    self = [super init];
    if (self) {
        _file = file;
        _h264Data = [NSData dataWithContentsOfFile:file];
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
    //NSLog(@"%@",data);
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
