//
//  YXNMTKView.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <MetalKit/MetalKit.h>

@interface YXNMTKView : MTKView

- (void)displayVideo:(CVPixelBufferRef)pixelBuffer;

@end



