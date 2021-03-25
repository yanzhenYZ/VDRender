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
@end


