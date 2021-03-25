//
//  YXSMKTView.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <MetalKit/MetalKit.h>

@interface YXSMKTView : MTKView

- (void)displayVideo:(CVPixelBufferRef)pixelBuffer;

@end

