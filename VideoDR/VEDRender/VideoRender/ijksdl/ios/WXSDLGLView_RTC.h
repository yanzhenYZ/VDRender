//
//  WXSDLGLView+WXSDLGLView_RTC.h
//  RTCEngineDemo
//
//  Created by zrj on 2020/9/24.
//  Copyright © 2020 xrs. All rights reserved.
//

#import "WXSDLGLView.h"
#import "YXVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@interface WXSDLGLView (WXSDLGLView_RTC)

-(void)displayData:(YXVideoData *)data;


- (void)displayBgra:(CVPixelBufferRef)pixelBuffer;
- (void)displayNv12:(CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END
