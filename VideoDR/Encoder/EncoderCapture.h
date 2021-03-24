//
//  EncoderCapture.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

static const int VIDEOTYPE = 1;

@protocol EncoderCaptureDelegate;
@interface EncoderCapture : NSObject
@property (nonatomic, weak) id<EncoderCaptureDelegate> delegate;

- (instancetype)initWithPlayer:(UIView *)player;

- (void)startRunning;
- (void)stopRunning;
@end

@protocol EncoderCaptureDelegate <NSObject>

- (void)capture:(EncoderCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
