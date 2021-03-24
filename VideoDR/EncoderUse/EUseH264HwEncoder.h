//
//  EUseH264HwEncoder.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import <CoreVideo/CVPixelBuffer.h>

@protocol EUseH264HwEncoderDelegate;
@interface EUseH264HwEncoder : NSObject
@property (nonatomic, weak) id<EUseH264HwEncoderDelegate> delegate;

- (void)startEncode:(int)width height:(int)height;
- (void)stop;

- (void)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

@protocol EUseH264HwEncoderDelegate <NSObject>

@optional

- (void)encoder:(EUseH264HwEncoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey;
- (void)encoder:(EUseH264HwEncoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps;

@end
