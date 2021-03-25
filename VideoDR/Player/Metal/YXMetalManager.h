//
//  YXMetalManager.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface YXMetalManager : NSObject
+ (instancetype)manager;

@property (nonatomic, strong, readonly) id<MTLDevice> device;

- (id<MTLCommandBuffer>)commandBuffer;
+ (MTLRenderPassDescriptor *)newRenderPassDescriptor:(id<MTLTexture>)texture;
- (id<MTLRenderPipelineState>)newRenderPipeline:(NSString *)vertex fragment:(NSString *)fragment;
@end


