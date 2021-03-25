//
//  H264HwEncoder.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import "H264HwEncoder.h"
#import <VideoToolbox/VideoToolbox.h>


@interface H264HwEncoder ()
@property (nonatomic, assign) int64_t frames;

- (void)sendSps:(NSData *)sps pps:(NSData *)pps;
- (void)sendData:(NSData *)data isKeyframe:(BOOL)isKeyframe;
@end

void YXVideoCompressionOutputCallback(void *outputCallbackRefCon,
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
    H264HwEncoder *encoder = (__bridge H264HwEncoder *)outputCallbackRefCon;
    //NSLog(@"123:%@", sampleBuffer);
    
    // Check if we have got a key frame first 判断当前帧是否为关键帧
    BOOL keyframe = !CFDictionaryContainsKey((CFDictionaryRef) CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0), kCMSampleAttachmentKey_NotSync);
    if (keyframe)
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


@implementation H264HwEncoder {
    VTCompressionSessionRef _encodeSession;
}

- (void)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer {
    VTEncodeInfoFlags flags;
    CMTime presentationTimeStamp = CMTimeMake(++_frames, 1000);
    OSStatus status = VTCompressionSessionEncodeFrame(_encodeSession, pixelBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, NULL, &flags);
    if (status != noErr) {
        NSLog(@"Encoder Error:%d", status);
    }
}

- (void)startEncode:(int)width height:(int)height {
    OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, YXVideoCompressionOutputCallback, (__bridge void *)(self), &_encodeSession);
    
    if (noErr != status) {
        NSLog(@"H264: Unable to create a H264 session code %d",status);
        return;
    }
    // 设置实时编码输出，降低编码延迟
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);

    // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
    SInt32 bitRate = width * height * 200;
    //2000 * 1024 -> assume 2 Mbits/s
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)(@(bitRate)));
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bitRate * 2 / 8), @1]); // Bps
    
    //??
//    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)(@(brate)));

    
    
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_Quality, (__bridge CFTypeRef)(@(1.0)));
    // 设置关键帧间隔，即gop size
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)(@(10)));
    VTCompressionSessionPrepareToEncodeFrames(_encodeSession);
}

- (void)stop
{
    if (NULL != _encodeSession) {
        VTCompressionSessionCompleteFrames(_encodeSession, kCMTimeInvalid);
        
        VTCompressionSessionInvalidate(_encodeSession);
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
