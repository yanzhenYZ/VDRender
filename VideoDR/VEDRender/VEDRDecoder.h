//
//  VEDRDecoder.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


static const int VIDEOTYPE = 0;

@protocol VEDRDecoderDelegate;
@interface VEDRDecoder : NSObject
@property (nonatomic, assign) id<VEDRDecoderDelegate> delegate;

- (void)decodeData:(NSData *)data;
@end

@protocol VEDRDecoderDelegate <NSObject>

- (void)decoder:(VEDRDecoder *)decoder didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
