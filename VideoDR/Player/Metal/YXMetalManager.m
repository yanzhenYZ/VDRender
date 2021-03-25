//
//  YXMetalManager.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "YXMetalManager.h"

@interface YXMetalManager ()
@property (nonatomic, strong) id<MTLLibrary> defaultLibrary;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@end

static id _manger;
@implementation YXMetalManager

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manger = [[self alloc] init];
    });
    return _manger;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manger = [super allocWithZone:zone];
    });
    return _manger;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _manger;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        _defaultLibrary = [_device newDefaultLibrary];
        
        //可以使用在工程中或者动态库中
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        //you must have a metal file in project
        NSString *path = [bundle pathForResource:@"default" ofType:@"metallib"];
        assert(path);
        if (!path) {
            NSLog(@"YXMetalManager make path error");
        } else {
            NSError *error = nil;
            _defaultLibrary = [_device newLibraryWithFile:path error:&error];
            if (error) {
                NSLog(@"YZMetalDevice newLibrary fail:%@", error.localizedDescription);
            }
        }
    }
    return self;
}

- (id<MTLCommandBuffer>)commandBuffer {
    return [_commandQueue commandBuffer];
}

+ (MTLRenderPassDescriptor *)newRenderPassDescriptor:(id<MTLTexture>)texture {
    MTLRenderPassDescriptor *desc = [[MTLRenderPassDescriptor alloc] init];
    desc.colorAttachments[0].texture = texture;
    desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
    desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    return desc;
}

- (id<MTLRenderPipelineState>)newRenderPipeline:(NSString *)vertex fragment:(NSString *)fragment {
    id<MTLFunction> vertexFunction = [_defaultLibrary newFunctionWithName:vertex];
    id<MTLFunction> fragmentFunction = [_defaultLibrary newFunctionWithName:fragment];
    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    if (@available(iOS 11.0, macOS 10.13, *)) {
        desc.rasterSampleCount = 1;
    } else {
        desc.sampleCount = 1;
    }
    desc.vertexFunction = vertexFunction;
    desc.fragmentFunction = fragmentFunction;
    
    NSError *error = nil;
    id<MTLRenderPipelineState> pipeline = [_device newRenderPipelineStateWithDescriptor:desc error:&error];
    if (error) {
        NSLog(@"YZMetalDevice new renderPipelineState failed: %@", error);
    }
    return pipeline;
}
@end
