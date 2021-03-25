//
//  YXDMTKView.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "YXDMTKView.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import "YXMetalManager.h"

@interface YXDMTKView ()<MTKViewDelegate>
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@end

@implementation YXDMTKView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.blackColor;
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        self.paused = YES;
        self.delegate = self;
        self.framebufferOnly = NO;
        self.enableSetNeedsDisplay = NO;
        self.device = YXMetalManager.manager.device;
        CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
    }
    return self;
}

- (void)displayVideo:(CVPixelBufferRef)pixelBuffer {
    
}

#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(MTKView *)view {
    if (self.texture == nil) { return; }
    id<MTLCommandBuffer> commandBuffer = [YXMetalManager.manager commandBuffer];
    id<MTLTexture> texture = view.currentDrawable.texture;
    if (!texture) {
        NSLog(@"CoreRtc M Error: view not has currentDrawable");
        return;
    }
    
    
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    texture = nil;
    self.texture = nil;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}
@end
