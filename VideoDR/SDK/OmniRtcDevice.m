//
//  OmniRtcDevice.m
//  MetalVideo
//
//  Created by yanzhen on 2021/4/1.
//

#import "OmniRtcDevice.h"
#import "OmniRtcVertexFragment.h"
#import "OmniRtcNV12.h"
#import "OmniRtcI420.h"

@interface OmniRtcDevice ()
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLCommandQueue> remoteCommandQueue;
@property (nonatomic, strong) id<MTLLibrary> defaultLibrary;
@property (nonatomic, strong) id<MTLLibrary> nv12Library;
@property (nonatomic, strong) id<MTLLibrary> i420Library;
@end

@implementation OmniRtcDevice
static OmniRtcDevice *_metalDevice;

+ (instancetype)defaultDevice {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _metalDevice = [[self alloc] init];
    });
    return _metalDevice;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        
        _defaultLibrary = [_device newLibraryWithSource:[NSString stringWithUTF8String:OmniRtcVertexFragment] options:NULL error:nil];
        if (_defaultLibrary == nil) { return nil; }
        
        _nv12Library = [_device newLibraryWithSource:[NSString stringWithUTF8String:OmniRtcNV12Shader] options:NULL error:nil];
        if (_nv12Library == nil) { return nil; }
        
        _i420Library = [_device newLibraryWithSource:[NSString stringWithUTF8String:OmniRtcI420] options:NULL error:nil];
        if (_i420Library == nil) { return nil; }
        
    }
    return self;
}
#pragma mark - use method

+ (MTLRenderPassDescriptor *)newRenderPassDescriptor:(id<MTLTexture>)texture {
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = texture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    return desc;
}

- (id<MTLRenderPipelineState>)defaultRenderPipeline {
    id<MTLFunction> vertexFunction = [_defaultLibrary newFunctionWithName:@"OmniRtcInputVertex"];
    id<MTLFunction> fragmentFunction = [_defaultLibrary newFunctionWithName:@"OmniRtcFragment"];
    return [self generateRenderPipeline:vertexFunction fragmentFunction:fragmentFunction];
}

- (id<MTLRenderPipelineState>)fullRangeRenderPipeline {
    id<MTLFunction> vertexFunction = [_nv12Library newFunctionWithName:@"OmniRtcYUVToRGBVertex"];
    id<MTLFunction> fragmentFunction = [_nv12Library newFunctionWithName:@"OmniRtcYUVConversionFullRangeFragment"];
    return [self generateRenderPipeline:vertexFunction fragmentFunction:fragmentFunction];
}

- (id<MTLRenderPipelineState>)i420RenderPipeline {
    id<MTLFunction> vertexFunction = [_i420Library newFunctionWithName:@"OmniRtcI420ToRGBVertex"];
    id<MTLFunction> fragmentFunction = [_i420Library newFunctionWithName:@"OmniRtcI420Fragment"];
    return [self generateRenderPipeline:vertexFunction fragmentFunction:fragmentFunction];
}

- (id<MTLRenderPipelineState>)generateRenderPipeline:(id<MTLFunction>)vertexFunction fragmentFunction:(id<MTLFunction>)fragmentFunction {
    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;//bgra
    if (@available(iOS 11.0, macOS 10.13, *)) {//每个像素中的采样点数
        desc.rasterSampleCount = 1;
    } else {
        desc.sampleCount = 1;
    }
    desc.vertexFunction = vertexFunction;
    desc.fragmentFunction = fragmentFunction;
    
    NSError *error = nil;
    id<MTLRenderPipelineState> pipeline = [_device newRenderPipelineStateWithDescriptor:desc error:&error];
    if (error) {
#if DEBUG
        NSLog(@"OmniRtcDevice new renderPipelineState failed: %@", error);
#endif
    }
    return pipeline;
}
@end
