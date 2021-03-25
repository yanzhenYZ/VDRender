//
//  VEDREncoder.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "VEDREncoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface VEDREncoder ()
@property (nonatomic, assign) int64_t frames;
@property (nonatomic, assign) BOOL gotPPS;

- (void)sendSps:(NSData *)sps pps:(NSData *)pps;
- (void)sendData:(NSData *)data isKeyframe:(BOOL)isKeyframe;
@end

void VEDRVideoCompressionOutputCallback(void *outputCallbackRefCon,
                                      void *sourceFrameRefCon,
                                      OSStatus status,
                                      VTEncodeInfoFlags infoFlags,
                                      CMSampleBufferRef sampleBuffer)
{
    if (status != 0) {
        NSLog(@"Compression Error:%d", status);
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    VEDREncoder *encoder = (__bridge VEDREncoder *)outputCallbackRefCon;
    //NSLog(@"123:%@", sampleBuffer);
    
    //todo
    // Check if we have got a key frame first 判断当前帧是否为关键帧
    BOOL keyframe = !CFDictionaryContainsKey((CFDictionaryRef) CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0), kCMSampleAttachmentKey_NotSync);
    if (keyframe && !encoder.gotPPS)
    //if (keyframe)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0 );
        if (statusCode == noErr)
        {
            // Found sps and now check for pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
            if (statusCode == noErr)
            {
                // Found pps
                //序列参数集
                NSData *spsData = [NSData dataWithBytes:(void*)sparameterSet length:sparameterSetSize];
                //图像参数集
                NSData *ppsData = [NSData dataWithBytes:(void*)pparameterSet length:pparameterSetSize];
                [encoder sendSps:spsData pps:ppsData];
                encoder.gotPPS = YES;
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;//返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            
            // Read the NAL unit length
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);// 获取nalu的长度，
            
            // Convert the length value from Big-endian to Little-endian
            // 大端模式转化为系统端模式
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData *data = [NSData dataWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            //[encoder.delegate didEncodedData:data isKeyFrame:keyframe];
            [encoder sendData:data isKeyframe:keyframe];
            // 读取下一个nalu，一次回调可能包含多个nalu
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
        
    }
}


@implementation VEDREncoder {
    VTCompressionSessionRef _encodeSession;
}

- (void)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer {
    VTEncodeInfoFlags flags;
    CMTime presentationTimeStamp = CMTimeMake(++_frames, 1000);
    OSStatus status = VTCompressionSessionEncodeFrame(_encodeSession, pixelBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, NULL, &flags);
    //kVTVideoDecoderBadDataErr
    if (status != noErr) {
        NSLog(@"Encoder Error:%d", status);
    }
}

- (void)startEncode:(int)width height:(int)height {
    int retryTimes = 0;
    while (VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, VEDRVideoCompressionOutputCallback, (__bridge void *)(self), &_encodeSession) != noErr && retryTimes < 5) {
        NSLog(@"H264: Unable to create a H264 session code");
        retryTimes ++;
        sleep(1);
    }
    
    int videoMaxKeyframeInterval = 10;
    int fps = 10;
    int bitrate = 800 * 1000;
    // 设置关键帧间隔，即gop size
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(videoMaxKeyframeInterval));
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(fps));
    // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bitrate));
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bitrate*1.5/8), @1]);
    // 设置实时编码输出，降低编码延迟
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_High_AutoLevel);
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    //if baseline delete this mode
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
    OSStatus status = VTCompressionSessionPrepareToEncodeFrames(_encodeSession);
    if (status != noErr) {
        NSLog(@"Encoder H264: prepare to encode frame failed");
    }
}

- (void)stop
{
    if (NULL != _encodeSession) {
        VTCompressionSessionCompleteFrames(_encodeSession, kCMTimeInvalid);
        
        //部分设备会出现问题？？
        //VTCompressionSessionInvalidate(_encodeSession);
        CFRelease(_encodeSession);
        _encodeSession = NULL;
    }
}

- (void)dealloc
{
    [self stop];
}
#pragma mark - helper
- (void)sendSps:(NSData *)sps pps:(NSData *)pps {
    if ([_delegate respondsToSelector:@selector(encoder:sendSps:pps:)]) {
        [_delegate encoder:self sendSps:sps pps:pps];
    }
}

- (void)sendData:(NSData *)data isKeyframe:(BOOL)isKeyframe {
    if ([_delegate respondsToSelector:@selector(encoder:sendData:isKeyFrame:)]) {
        [_delegate encoder:self sendData:data isKeyFrame:isKeyframe];
    }
}
@end

