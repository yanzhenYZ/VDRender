//
//  YXYMTKView.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "YXYMTKView.h"
#import "YXMetalManager.h"

@interface YXYMTKView ()<MTKViewDelegate>
@property (nonatomic, strong) id<MTLTexture> textureY;
@property (nonatomic, strong) id<MTLTexture> textureU;
@property (nonatomic, strong) id<MTLTexture> textureV;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@end

@implementation YXYMTKView

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
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.clipsToBounds = YES;
        self.paused = YES;
        self.delegate = self;
        self.framebufferOnly = NO;
        self.enableSetNeedsDisplay = NO;
        self.device = YXMetalManager.manager.device;
        CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
        _pipeline = [YXMetalManager.manager newRenderPipeline:@"YZYUVDataToRGBVertex" fragment:@"YZYUVDataConversionFullRangeFragment"];
    }
    return self;
}

- (void)displayVideo:(CVPixelBufferRef)pixelBuffer {
    size_t w = CVPixelBufferGetWidth(pixelBuffer);
    size_t h = CVPixelBufferGetHeight(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int8_t *yBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    size_t yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    MTLTextureDescriptor *yDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:w height:h mipmapped:NO];
    yDesc.usage = MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    id<MTLTexture> textureY = [self.device newTextureWithDescriptor:yDesc];
    [textureY replaceRegion:MTLRegionMake2D(0, 0, textureY.width, textureY.height) mipmapLevel:0 withBytes:yBuffer bytesPerRow:yStride];
    _textureY = textureY;
    
    int8_t *uBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    size_t uStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    MTLTextureDescriptor *uDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:w / 2 height:h / 2 mipmapped:NO];
    uDesc.usage = MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    id<MTLTexture> textureU = [self.device newTextureWithDescriptor:uDesc];
    [textureU replaceRegion:MTLRegionMake2D(0, 0, textureU.width, textureU.height) mipmapLevel:0 withBytes:uBuffer bytesPerRow:uStride];
    _textureU = textureU;
    
    int8_t *vBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    size_t vStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);
    MTLTextureDescriptor *vDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:w / 2 height:h / 2 mipmapped:NO];
    vDesc.usage = MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    id<MTLTexture> textureV = [self.device newTextureWithDescriptor:vDesc];
    [textureV replaceRegion:MTLRegionMake2D(0, 0, textureV.width, textureV.height) mipmapLevel:0 withBytes:vBuffer bytesPerRow:vStride];
    _textureV = textureV;
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    self.drawableSize = CGSizeMake(w, h);
    [self draw];
}

- (void)_displayVideo:(CVPixelBufferRef)pixelBuffer {
    size_t w = CVPixelBufferGetWidth(pixelBuffer);
    size_t h = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureRef textureRef = NULL;
    size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatR8Unorm, width, height, 0, &textureRef);
    if(status != kCVReturnSuccess) {
        return;
    }
    _textureY = CVMetalTextureGetTexture(textureRef);
    CFRelease(textureRef);
    textureRef = NULL;
    
    width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatR8Unorm, width, height, 1, &textureRef);
    if(status != kCVReturnSuccess) {
        return;
    }
    _textureU = CVMetalTextureGetTexture(textureRef);
    CFRelease(textureRef);
    textureRef = NULL;
    
    width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 2);
    height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 2);
    status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatR8Unorm, width, height, 2, &textureRef);
    if(status != kCVReturnSuccess) {
        return;
    }
    _textureV = CVMetalTextureGetTexture(textureRef);
    CFRelease(textureRef);
    textureRef = NULL;
    
    self.drawableSize = CGSizeMake(w, h);
    [self draw];
}

#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(MTKView *)view {
    if (!view.currentDrawable || !_textureY || !_textureU || !_textureV) { return; }
    id<MTLTexture> outTexture = view.currentDrawable.texture;
    
    MTLRenderPassDescriptor *desc = [YXMetalManager newRenderPassDescriptor:outTexture];
    desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
    
    id<MTLCommandBuffer> commandBuffer = [YXMetalManager.manager commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
    if (!encoder) {
        NSLog(@"YZI420Player render endcoder Fail");
        return;
    }
    [encoder setFrontFacingWinding:MTLWindingClockwise];
    [encoder setRenderPipelineState:self.pipeline];

    simd_float8 vertices = {-1, 1, 1, 1, -1, -1, 1, -1};
    [encoder setVertexBytes:&vertices length:sizeof(simd_float8) atIndex:0];

    simd_float8 textureCoordinates = {0, 0, 1, 0, 0, 1, 1, 1};
    [encoder setVertexBytes:&textureCoordinates length:sizeof(simd_float8) atIndex:1];
    [encoder setFragmentTexture:_textureY atIndex:0];
    [encoder setVertexBytes:&textureCoordinates length:sizeof(simd_float8) atIndex:2];
    [encoder setFragmentTexture:_textureU atIndex:1];
    [encoder setVertexBytes:&textureCoordinates length:sizeof(simd_float8) atIndex:3];
    [encoder setFragmentTexture:_textureV atIndex:2];

    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];

    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    _textureY = nil;
    _textureU = nil;
    _textureV = nil;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}
@end
