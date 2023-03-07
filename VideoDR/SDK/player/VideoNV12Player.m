//
//  VideoNV12Player.m
//  myvideo
//
//  Created by yanzhen on 2021/4/1.
//  Copyright © 2021 apple. All rights reserved.
//

#import "VideoNV12Player.h"
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import "OmniRtcDevice.h"
#import "OmniRtcOrientation.h"

@interface OmniRtcVideoNV12Player ()<MTKViewDelegate>
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLTexture> textureY;
@property (nonatomic, strong) id<MTLTexture> textureUV;
@end

@implementation OmniRtcVideoNV12Player
- (void)setupMetal {
    self.mtkView = [[MTKView alloc] initWithFrame:CGRectZero];
    self.mtkView.backgroundColor = UIColor.blackColor;
    self.mtkView.contentMode = UIViewContentModeScaleAspectFill;
    self.mtkView.clipsToBounds = YES;
    self.mtkView.paused = YES;
    self.mtkView.delegate = self;
    self.mtkView.framebufferOnly = NO;
    self.mtkView.enableSetNeedsDisplay = NO;
    self.mtkView.device = OmniRtcDevice.defaultDevice.device;
    self.commandQueue = [self.mtkView.device newCommandQueue];
    CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
    _pipelineState = [OmniRtcDevice.defaultDevice fullRangeRenderPipeline];
    
}

- (void)setRemoteVideoViewInMainThread:(UIView *)videoView fillMode:(UIViewContentMode)mode mirror:(BOOL)mirror {
    [super setRemoteVideoViewInMainThread:videoView fillMode:mode mirror:mirror];
    self.render = NO;
    if (self.superview == videoView) {
        [videoView addSubview:self];
        _mtkView.contentMode = mode;
        self.render = YES;
        return;
    }
    if (self.superview) {
        [self removeFromSuperview];
    }
    
    if (videoView == nil) {
        return;
    }
    for (UIView *subView in videoView.subviews) {
        if ([subView isKindOfClass:[OmniRtcVideoPlayerBackView class]]) {
            [subView removeFromSuperview];
        }
    }
    
    if (!_mtkView) {
        [self setupMetal];
        [self addSubview:self.mtkView];
    }
    
    _mtkView.contentMode = mode;
    [videoView addSubview:self];
    self.frame = videoView.bounds;
    self.mtkView.frame = self.bounds;
    self.render = YES;
}

- (void)displayVideo:(CVPixelBufferRef)pixelBuffer {
    [super displayVideo:pixelBuffer];
    if (!self.render) { return; }
    CVPixelBufferRetain(pixelBuffer);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
   
    size_t w = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t h = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    CVMetalTextureRef textureRef = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatR8Unorm, w, h, 0, &textureRef);
    if(status != kCVReturnSuccess) {
        CVPixelBufferRelease(pixelBuffer);
        if (textureRef) {
            CFRelease(textureRef);
            textureRef = NULL;
        }
        
        return;
    }
    _textureY = CVMetalTextureGetTexture(textureRef);
    CFRelease(textureRef);
    textureRef = NULL;
    
    w = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    h = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatRG8Unorm, w, h, 1, &textureRef);
    if(status != kCVReturnSuccess) {
        CVPixelBufferRelease(pixelBuffer);
        if (textureRef) {
            CFRelease(textureRef);
            textureRef = NULL;
        }
        
        return;
    }
    _textureUV = CVMetalTextureGetTexture(textureRef);
    CFRelease(textureRef);
    textureRef = NULL;
    
    CVPixelBufferRelease(pixelBuffer);
    self.mtkView.drawableSize = CGSizeMake(width, height);
    [self.mtkView draw];
}

#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(MTKView *)view {
    if (!self.textureY || !self.textureUV) { return; }
    id<MTLTexture> texture = view.currentDrawable.texture;
    if (!texture) {
#if DEBUG
        NSLog(@"CoreRtc M Error: view not has currentDrawable");
#endif
        
    }
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *desc = view.currentRenderPassDescriptor;
    if (!desc) {
        desc = [OmniRtcDevice newRenderPassDescriptor:texture];
    }
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
      
#if DEBUG
        NSLog(@"OmniRtcVideoNV12Player render endcoder Fail");
#endif
        return;
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:self.pipelineState];
    
    simd_float8 vertices = [OmniRtcOrientation defaultVertices];
    [encoder setVertexBytes:&vertices length:sizeof(simd_float8) atIndex:0];
    
    simd_float8 textureCoordinates = [OmniRtcOrientation getTextureCoordinates:0 mirror:self.mirror];
    [encoder setVertexBytes:&textureCoordinates length:sizeof(simd_float8) atIndex:1];
    [encoder setFragmentTexture:_textureY atIndex:0];
    [encoder setVertexBytes:&textureCoordinates length:sizeof(simd_float8) atIndex:2];
    [encoder setFragmentTexture:_textureUV atIndex:1];

    id<MTLBuffer> uniformBuffer = [self.mtkView.device newBufferWithBytes:kOmniRtcColorConversion601FullRange length:sizeof(float) * 12 options:MTLResourceCPUCacheModeDefaultCache];
    [encoder setFragmentBuffer:uniformBuffer offset:0 atIndex:0];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    
    self.textureY = nil;
    self.textureUV = nil;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

#pragma mark - system
-(void)layoutSubviews {
    [super layoutSubviews];
    self.mtkView.frame = self.bounds;
}

- (void)dealloc {
    if (_textureCache) {
        CVMetalTextureCacheFlush(_textureCache, 0);
        CFRelease(_textureCache);
        _textureCache = nil;
    }
}
@end
