//
//  OmniRtcDevice.h
//  MetalVideo
//
//  Created by yanzhen on 2021/4/1.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface OmniRtcDevice : NSObject
@property (nonatomic, strong, readonly) id<MTLDevice> device;

+ (instancetype)defaultDevice;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

+ (MTLRenderPassDescriptor *)newRenderPassDescriptor:(id<MTLTexture>)texture;

- (id<MTLRenderPipelineState>)fullRangeRenderPipeline;
- (id<MTLRenderPipelineState>)defaultRenderPipeline;
- (id<MTLRenderPipelineState>)i420RenderPipeline;

@end

