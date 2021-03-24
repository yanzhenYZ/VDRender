//
//  H264HwEncoder.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import <CoreVideo/CVPixelBuffer.h>

@protocol H264HwEncoderDelegate;
@interface H264HwEncoder : NSObject
@property (nonatomic, weak) id<H264HwEncoderDelegate> delegate;

- (void)startEncode:(int)width height:(int)height;
- (void)stop;

- (void)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

@protocol H264HwEncoderDelegate <NSObject>

@optional

- (void)encoder:(H264HwEncoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey;
- (void)encoder:(H264HwEncoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps;

@end

