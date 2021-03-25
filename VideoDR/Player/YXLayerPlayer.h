//
//  YXLayerPlayer.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface YXLayerPlayer : UIView

- (void)displayVideo:(CVPixelBufferRef)pixelBuffer;
- (void)displayBuffer:(CMSampleBufferRef)sampleBuffer;

@end

