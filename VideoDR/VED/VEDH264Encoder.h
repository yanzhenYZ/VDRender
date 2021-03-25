//
//  VEDH264Encoder.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <CoreVideo/CVPixelBuffer.h>

@protocol VEDH264EncoderDelegate;
@interface VEDH264Encoder : NSObject
@property (nonatomic, weak) id<VEDH264EncoderDelegate> delegate;

- (void)startEncode:(int)width height:(int)height;
- (void)stop;

- (void)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

@protocol VEDH264EncoderDelegate <NSObject>

@optional

- (void)encoder:(VEDH264Encoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey;
- (void)encoder:(VEDH264Encoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps;

@end
