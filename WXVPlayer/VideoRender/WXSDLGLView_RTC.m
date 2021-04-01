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

#pragma mark - add 20210401
- (void)displayNv12:(CVPixelBufferRef)pixelBuffer rotation:(int)rotation {
    WX_SDL_VoutOverlay bb;
    bb.format = SDL_FCC_NV12;
    bb.w = (int)CVPixelBufferGetWidth(pixelBuffer);
    bb.h = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    bb.pixels[0] = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    bb.pixels[1] = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    bb.pitches[0] = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    bb.pitches[1] = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    
    bb.planes = 2;
    bb.rotation = rotation;
    bb.sar_den = 0;
    bb.sar_num = 0;
    [self display:&bb];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)displayBgra:(CVPixelBufferRef)pixelBuffer {
    WX_SDL_VoutOverlay bb;
    bb.format = SDL_FCC_RV32;
    
    bb.w = (int)CVPixelBufferGetWidth(pixelBuffer);
    bb.h = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *address = CVPixelBufferGetBaseAddress(pixelBuffer);
    bb.pixels[0] = address;
    bb.pitches[0] = CVPixelBufferGetBytesPerRow(pixelBuffer);
    bb.planes = 1;
    bb.rotation = 0;
    bb.sar_den = 0;
    bb.sar_num = 0;
    [self display:&bb];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}
@end