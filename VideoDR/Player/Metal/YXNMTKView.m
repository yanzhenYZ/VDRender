//
//  YXNMTKView.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "YXNMTKView.h"
#import "YXMetalManager.h"

@interface YXNMTKView ()<MTKViewDelegate>
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@end

@implementation YXNMTKView

- (void)dealloc
{
    if (_textureCache) {
        CVMetalTextureCacheFlush(_textureCache, 0);
        CFRelease(_textureCache);
        _textureCache = nil;
    }
}

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
        _pipeline = [YXMetalManager.manager newRenderPipeline:@"YZInputVertex" fragment:@"YZFragment"];
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
