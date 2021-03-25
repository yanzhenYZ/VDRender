//
//  VEDH264Decoder.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol VEDH264DecoderDelegate;
@interface VEDH264Decoder : NSObject
@property (nonatomic, assign) id<VEDH264DecoderDelegate> delegate;

- (void)decodeData:(NSData *)data;
@end

@protocol VEDH264DecoderDelegate <NSObject>

- (void)decoder:(VEDH264Decoder *)decoder didOutputSampleBuffer:(CMSampleBufferRef)sample;

@end
