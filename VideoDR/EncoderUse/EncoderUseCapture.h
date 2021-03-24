//
//  EncoderUseCapture.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

@protocol EncoderUseCaptureDelegate;
@interface EncoderUseCapture : NSObject
@property (nonatomic, weak) id<EncoderUseCaptureDelegate> delegate;

- (instancetype)initWithPlayer:(UIView *)player;

- (void)startRunning;
- (void)stopRunning;
@end

@protocol EncoderUseCaptureDelegate <NSObject>

- (void)capture:(EncoderUseCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
