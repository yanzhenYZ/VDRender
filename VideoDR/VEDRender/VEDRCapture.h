//
//  VEDRCapture.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

@protocol VEDRCaptureDelegate;
@interface VEDRCapture : NSObject
@property (nonatomic, weak) id<VEDRCaptureDelegate> delegate;

- (instancetype)initWithPlayer:(UIView *)player;

- (void)startRunning;
- (void)stopRunning;
@end

@protocol VEDRCaptureDelegate <NSObject>

- (void)capture:(VEDRCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
