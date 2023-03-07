//
//  VideoPlayerBackView.h
//  myvideo
//
//  Created by yanzhen on 2021/3/8.
//  Copyright © 2021 apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CVPixelBuffer.h>

@protocol OmniRtcVideoPlayerBackViewDelegate;
@interface OmniRtcVideoPlayerBackView : UIView
@property (nonatomic, assign) BOOL render;
@property (nonatomic, assign) BOOL mirror;

- (void)setRemoteVideoViewInMainThread:(UIView *)videoView fillMode:(UIViewContentMode)mode mirror:(BOOL)mirror;
- (void)displayVideo:(CVPixelBufferRef)pixelBuffer;

@end

