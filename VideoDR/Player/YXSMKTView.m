//
//  YXSMKTView.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "YXSMKTView.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface YXSMKTView ()<MTKViewDelegate>
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, strong) MPSImageGaussianBlur *filter;
@end

@implementation YXSMKTView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.blackColor;
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.clipsToBounds = YES;
        self.paused = YES;
        self.delegate = self;
        self.framebufferOnly = NO;
        self.enableSetNeedsDisplay = NO;
        self.device = MTLCreateSystemDefaultDevice();
        self.commandQueue = [self.device newCommandQueue];
        CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
        _filter = [[MPSImageGaussianBlur alloc] initWithDevice:self.device sigma:0];
    }
    return self;
}

- (void)displayVideo:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferRetain(pixelBuffer);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVMetalTextureRef tmpTexture = NULL;
    CVReturn status =  CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture);
    if (status != kCVReturnSuccess) {
        CVPixelBufferRelease(pixelBuffer);
        return;
    }
    
    self.drawableSize = CGSizeMake(width, height);
    self.texture = CVMetalTextureGetTexture(tmpTexture);
    CFRelease(tmpTexture);
    
    [self draw];
    CVPixelBufferRelease(pixelBuffer);
}
#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(MTKView *)view {
    if (self.texture == nil) { return; }
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLTexture> texture = view.currentDrawable.texture;
    if (!texture) {
        NSLog(@"CoreRtc M Error: view not has currentDrawable");
        return;
    }
    [_filter encodeToCommandBuffer:commandBuffer sourceTexture:self.texture destinationTexture:texture];
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    texture = nil;
    self.texture = nil;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}
@end
