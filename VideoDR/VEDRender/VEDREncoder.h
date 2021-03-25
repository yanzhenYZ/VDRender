//
//  VEDREncoder.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <CoreVideo/CVPixelBuffer.h>

@protocol VEDREncoderDelegate;
@interface VEDREncoder : NSObject
@property (nonatomic, weak) id<VEDREncoderDelegate> delegate;

- (void)startEncode:(int)width height:(int)height;
- (void)stop;

- (void)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

@protocol VEDREncoderDelegate <NSObject>

@optional

- (void)encoder:(VEDREncoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey;
- (void)encoder:(VEDREncoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps;

@end

