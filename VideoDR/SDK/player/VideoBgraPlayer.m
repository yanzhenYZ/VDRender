//
//  VideoBgraPlayer.m
//  myvideo
//
//  Created by yanzhen on 2022/7/14.
//  Copyright © 2022 apple. All rights reserved.
//

#import "VideoBgraPlayer.h"
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import "OmniRtcDevice.h"
#import "OmniRtcOrientation.h"

@interface OmniRtcVideoBgraPlayer ()<MTKViewDelegate>
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLTexture> texture;
@end

@implementation OmniRtcVideoBgraPlayer
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
    _pipelineState = [OmniRtcDevice.defaultDevice defaultRenderPipeline];
    
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
   
    CVMetalTextureRef textureRef = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &textureRef);
    if(status != kCVReturnSuccess) {
        CVPixelBufferRelease(pixelBuffer);
        if (textureRef) {
            CFRelease(textureRef);
            textureRef = NULL;
        }
        
        return;
    }
    _texture = CVMetalTextureGetTexture(textureRef);
    CFRelease(textureRef);
    textureRef = NULL;
    
    CVPixelBufferRelease(pixelBuffer);
    if (!CGSizeEqualToSize(self.mtkView.drawableSize, CGSizeMake(width, height)) ) {
        self.mtkView.drawableSize = CGSizeMake(width, height);
    }
    [self.mtkView draw];
}

#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(MTKView *)view {
    if (!self.texture) { return; }
    id<MTLTexture> texture = view.currentDrawable.texture;
    if (!texture) {
#if DEBUG
        NSLog(@"CoreRtc MB Error: view not has currentDrawable");
#endif
        
        return;
    }
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *desc = view.currentRenderPassDescriptor;
    if (!desc) {
        desc = [OmniRtcDevice newRenderPassDescriptor:texture];
    }
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        //[self renderFrameError:311 info:nil reset:NO];
#if DEBUG
        NSLog(@"OmniRtcVideoBgraPlayer render endcoder Fail");
#endif
        return;
    }
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:self.pipelineState];
    
    simd_float8 vertices = [OmniRtcOrientation defaultVertices];
    [encoder setVertexBytes:&vertices length:sizeof(simd_float8) atIndex:0];
    
    simd_float8 textureCoordinates = [OmniRtcOrientation getTextureCoordinates:0 mirror:self.mirror];
    [encoder setVertexBytes:&textureCoordinates length:sizeof(simd_float8) atIndex:1];
    [encoder setFragmentTexture:_texture atIndex:0];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    
    self.texture = nil;
    
    //[self videoFrameRendered];
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
