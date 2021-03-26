//
//  YZLibyuv.h
//  YZLibyuv
//
//  Created by yanzhen on 2021/3/3.
//

#import <Foundation/Foundation.h>
#import "YZLibVideoData.h"

@protocol YZLibyuvDelegate;
@interface YZLibyuv : NSObject
@property (nonatomic, assign) id<YZLibyuvDelegate> delegate;

- (void)inputVideoData:(YZLibVideoData *)videoData;

+ (void)BGRAToI420:(uint8_t *)bgra bgraStride:(int)bgraStride dstY:(uint8_t *)y strideY:(int)strideY dstU:(uint8_t *)u strideU:(int)strideU dstV:(uint8_t *)v strideV:(int)strideV width:(int)width height:(int)height;
@end

@protocol YZLibyuvDelegate <NSObject>

- (void)libyuv:(YZLibyuv *)yuv pixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
