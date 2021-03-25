//
//  VEDUseCapture.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

@protocol VEDUseCaptureDelegate;
@interface VEDUseCapture : NSObject
@property (nonatomic, weak) id<VEDUseCaptureDelegate> delegate;

- (instancetype)initWithPlayer:(UIView *)player;

- (void)startRunning;
- (void)stopRunning;
@end

@protocol VEDUseCaptureDelegate <NSObject>

- (void)capture:(VEDUseCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

