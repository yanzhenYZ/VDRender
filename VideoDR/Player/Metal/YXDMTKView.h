//
//  YXDMTKView.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <MetalKit/MetalKit.h>

@interface YXDMTKView : MTKView

- (void)displayVideo:(CVPixelBufferRef)pixelBuffer;

@end

