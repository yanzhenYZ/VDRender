//
//  VideoPlayerBackView.m
//  myvideo
//
//  Created by yanzhen on 2021/3/8.
//  Copyright © 2021 apple. All rights reserved.
//

#import "VideoPlayerBackView.h"

@interface OmniRtcVideoPlayerBackView ()
@property (nonatomic, assign) CFAbsoluteTime displayTime;
@end

@implementation OmniRtcVideoPlayerBackView

-(void)dealloc
{
    [OmniRtcVideoPlayerBackView syncMainThread:^{
        [self removeFromSuperview];
    }];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.blackColor;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)displayVideo:(CVPixelBufferRef)pixelBuffer {

}

- (void)setRemoteVideoViewInMainThread:(UIView *)videoView fillMode:(UIViewContentMode)mode mirror:(BOOL)mirror  {
    _mirror = mirror;
}



-(void)setVideoMirror:(BOOL)mirror {
    _mirror = mirror;
}

- (void)videoFrameRendered {
    
}

+ (void)syncMainThread:(void(^)(void))block {
    if (NSThread.isMainThread) {
        !block ?: block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}
@end
