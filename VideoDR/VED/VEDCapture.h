//
//  VEDCapture.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

@protocol VEDCaptureDelegate;
@interface VEDCapture : NSObject
@property (nonatomic, weak) id<VEDCaptureDelegate> delegate;

- (instancetype)initWithPlayer:(UIView *)player;

- (void)startRunning;
- (void)stopRunning;
@end

@protocol VEDCaptureDelegate <NSObject>

- (void)capture:(VEDCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

