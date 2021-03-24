//
//  RenderCapture.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

static const int VIDEOTYPE = 1;

@protocol RenderCaptureDelegate;
@interface RenderCapture : NSObject
@property (nonatomic, weak) id<RenderCaptureDelegate> delegate;

- (instancetype)initWithPlayer:(UIView *)player;

- (void)startRunning;
- (void)stopRunning;
@end

@protocol RenderCaptureDelegate <NSObject>

- (void)capture:(RenderCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

