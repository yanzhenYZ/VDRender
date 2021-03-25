//
//  VEDUseDecoder.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol VEDUseDecoderDelegate;
@interface VEDUseDecoder : NSObject
@property (nonatomic, assign) id<VEDUseDecoderDelegate> delegate;

- (void)decodeData:(NSData *)data;
@end

@protocol VEDUseDecoderDelegate <NSObject>

- (void)decoder:(VEDUseDecoder *)decoder didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
