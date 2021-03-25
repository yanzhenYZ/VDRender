//
//  YXLayerPlayer.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "YXLayerPlayer.h"

@interface YXLayerPlayer ()
@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;
@end

@implementation YXLayerPlayer

+(Class)layerClass {
    return [AVSampleBufferDisplayLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _displayLayer = (AVSampleBufferDisplayLayer *)self.layer;
    }
    return self;
}
/**
 640x480
 3% 20MB
 
 */
-(void)displayVideo:(CVPixelBufferRef)pixelBuffer {
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    //获取视频信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);

    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
    NSParameterAssert(result == 0 && sampleBuffer != NULL);
    CFRelease(videoInfo);

    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);

    [_displayLayer enqueueSampleBuffer:sampleBuffer];
    if (_displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [_displayLayer flush];
    }
    CFRelease(sampleBuffer);
}

- (void)displayBuffer:(CMSampleBufferRef)sampleBuffer {
    [_displayLayer enqueueSampleBuffer:sampleBuffer];
    if (_displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [_displayLayer flush];
    }
}
@end
