//
//  VEDUseEncoder.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <CoreVideo/CVPixelBuffer.h>

@protocol VEDUseEncoderDelegate;
@interface VEDUseEncoder : NSObject
@property (nonatomic, weak) id<VEDUseEncoderDelegate> delegate;

- (void)startEncode:(int)width height:(int)height;
- (void)stop;

- (void)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

@protocol VEDUseEncoderDelegate <NSObject>

@optional

- (void)encoder:(VEDUseEncoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey;
- (void)encoder:(VEDUseEncoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps;

@end
