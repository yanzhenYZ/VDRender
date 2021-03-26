//
//  WXSDLGLView+WXSDLGLView_RTC.m
//  RTCEngineDemo
//
//  Created by zrj on 2020/9/24.
//  Copyright © 2020 xrs. All rights reserved.
//

#import "WXSDLGLView_RTC.h"

@implementation WXSDLGLView (WXSDLGLView_RTC)

-(void)tranfer:(YXVideoData *)data to:(WX_SDL_VoutOverlay *)bb {
    bb->format = SDL_FCC_YV12;
    bb->w = data.width;
    bb->h = data.height;
    bb->pixels[0] = (UInt8*) data.yBuffer;
    bb->pixels[1] = (UInt8*)data.vBuffer;
    bb->pixels[2] = (UInt8*) data.uBuffer;
    bb->pitches[0] = data.yStride;
    bb->pitches[1] = data.vStride;
    bb->pitches[2] = data.uStride;
    bb->planes = 3;
    bb->rotation = 0;
    bb->sar_den = 0;
    bb->sar_num = 0;
}

- (void)displayData:(YXVideoData *)data {
    if(data == nil)
        return;

    WX_SDL_VoutOverlay bb;
    [self tranfer:data to:&bb];
    [self display:&bb];
}


@end
