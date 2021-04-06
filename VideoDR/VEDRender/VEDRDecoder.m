//
//  VEDRDecoder.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "VEDRDecoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface VEDRDecoder ()
@property (nonatomic) BOOL isKeyFrame;

- (void)outoutPixelBuffer:(CVImageBufferRef)imageBuffer;
@end

static void VEDRDidDecompressH264(void * CM_NULLABLE decompressionOutputRefCon,
                              void * CM_NULLABLE sourceFrameRefCon,
                              OSStatus status,
                              VTDecodeInfoFlags infoFlags,
                              CM_NULLABLE CVImageBufferRef imageBuffer,
                              CMTime presentationTimeStamp,
                              CMTime presentationDuration )
{
    if (imageBuffer == nil || status != noErr) {
        NSLog(@"YXDecoder imageBuffer is nil, status is [%d] !!!!!", (int)status);
        return;
    }
    VEDRDecoder* decoder = (__bridge VEDRDecoder *)decompressionOutputRefCon;
    [decoder outoutPixelBuffer:imageBuffer];
}

@implementation VEDRDecoder {
    VTDecompressionSessionRef _decompressionSession;
    CMVideoFormatDescriptionRef _formatDescription;
    uint8_t *_pps;
    uint8_t *_sps;
    size_t _spsSize;
    size_t _ppsSize;
}

- (void)dealloc
{
    if (_decompressionSession) {
        VTDecompressionSessionInvalidate(_decompressionSession);
        CFRelease(_decompressionSession);
        _decompressionSession = NULL;
    }
    
    if (_formatDescription) {
        CFRelease(_formatDescription);
        _formatDescription = NULL;
    }
    
    if (_sps) {
        free(_sps);
        _sps = NULL;
    }
    
    if (_pps) {
        free(_pps);
        _pps = NULL;
    }
}

- (void)decodeData:(NSData *)data {
    uint8_t *frame = (uint8_t *)data.bytes;
    uint32_t frameSize = (uint32_t)data.length;
    //前面拼接了4个字节，取出第五个字节做判断
    int nalu_type = (frame[4] & 0x1F);
    
    //nal数据的长度
    uint32_t nalSize = (uint32_t)(frameSize - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    /*
    由于VideoToolbox接口只接受MP4容器格式，当接收到Elementary Stream形式的H.264流，需把Start Code（3- or 4-Byte Header）换成Length（4-Byte Header）。
     参考工程中的图片或者http://www.cnblogs.com/sunminmin/p/4976418.html
     //rtsp://192.168.2.73:1935/vod/sample.mp4
     */
    //用前4个字节来表示nalSize
    frame[0] = pNalSize[3];
    frame[1] = pNalSize[2];
    frame[2] = pNalSize[1];
    frame[3] = pNalSize[0];
    BOOL reset = NO;
    BOOL sps = NO;
    switch (nalu_type)
    {
        case 0x06://sei not decoder
            return;
            break;
        case 0x07://SPS
        {
            sps = YES;
            if (_sps == NULL || _spsSize != nalSize
                || memcmp(_sps, frame+4, _spsSize) != 0)
            {
                if (_sps != NULL) {
                    free(_sps);
                }
                _spsSize = nalSize;
                if (_spsSize <= 0) {
                    return;
                }
                _sps = (uint8_t *)malloc(_spsSize);
                memcpy(_sps, frame+4, _spsSize);
                reset = YES;
            }
        }
            break;
        case 0x08://PPS
        {
            sps = YES;
            if (_pps == NULL || _ppsSize != nalSize
                || memcmp(_pps, frame+4, _ppsSize) != 0)
            {
                if (_pps != NULL) {
                    free(_pps);
                }
                _ppsSize = nalSize;
                if (_ppsSize <= 0) {
                    return;
                }
                _pps = (uint8_t *)malloc(_ppsSize);
                memcpy(_pps, frame+4, _ppsSize);
                reset = YES;
            }
        }
            break;
            //0x01  //B/P
            //0x05 I frame
        default:
            break;
    }
    if ([self initH264Decoder:reset] && !sps) {
        [self decompressWithNalUint:data];
    }
}

#pragma mark - helper
- (void)outoutPixelBuffer:(CVImageBufferRef)imageBuffer {
    if ([_delegate respondsToSelector:@selector(decoder:didOutputPixelBuffer:)]) {
        [_delegate decoder:self didOutputPixelBuffer:imageBuffer];
    }
}

-(BOOL)initH264Decoder:(BOOL)reset
{
    if (reset)
    {
        if (_decompressionSession) {
            CFRelease(_decompressionSession);
            _decompressionSession = NULL;
        }
        
        if (_formatDescription) {
            CFRelease(_formatDescription);
            _formatDescription = NULL;
        }
    }
    
    if (_decompressionSession)
    {
        return true;
    }
    
    if (_spsSize == 0 || _ppsSize == 0) { return NO; }
    const uint8_t * const parameterSetPointers[2] = {_sps, _pps};
    const size_t parameterSetSizes[2] = {_spsSize, _ppsSize};
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2,//parameter count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4,//NAL start code size
                                                                          &(_formatDescription));
    if(status != noErr) {
        NSLog(@"Creates a format description units: %d", (int)status);
        return NO;
    }
    
    const void* keys[] = { kCVPixelBufferPixelFormatTypeKey};
    //kCVPixelFormatType_420YpCbCr8Planar is YUV420, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    uint32_t biPlanarType = kCVPixelFormatType_32BGRA;
    if (VIDEOTYPE == 1) {
        biPlanarType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    } else if (VIDEOTYPE == 2) {
        biPlanarType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
    } else if (VIDEOTYPE == 3) {
        biPlanarType = kCVPixelFormatType_420YpCbCr8Planar;
    }
    
    const void *values[] = {CFNumberCreate(NULL, kCFNumberSInt32Type, &biPlanarType)};
    CFDictionaryRef attributes = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    //kVTVideoDecoderNotAvailableNowErr
    VTDecompressionOutputCallbackRecord outputCallBaclRecord;
    outputCallBaclRecord.decompressionOutputRefCon = (__bridge void*)self;
    outputCallBaclRecord.decompressionOutputCallback = VEDRDidDecompressH264;
    status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                          _formatDescription,
                                          NULL, attributes,
                                          &outputCallBaclRecord,
                                          &_decompressionSession);
    CFRelease(attributes);
    if(status != noErr) {
        NSLog(@"YXDecoder Error code: %d",(int)status);
        return NO;
    }
    return YES;
}

-(void)decompressWithNalUint:(NSData *)data
{
    CMBlockBufferRef blockBufferRef = NULL;
    
    //1.Fetch video data and generate CMBlockBuffer
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                         (void *)data.bytes,
                                                         data.length,
                                                         kCFAllocatorNull,
                                                         NULL,
                                                         0,
                                                         data.length,
                                                         0,
                                                         &blockBufferRef);
    //2.Create CMSampleBuffer
    if(status == kCMBlockBufferNoErr){
        CMSampleBufferRef sampleBufferRef = NULL;
        const size_t sampleSizes[] = {data.length};
        OSStatus createStatus = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                                          blockBufferRef,
                                                          _formatDescription,
                                                          1,
                                                          0,
                                                          NULL,
                                                          1,
                                                          sampleSizes,
                                                          &sampleBufferRef);
        
        //3.Create CVPixelBuffer
        if(createStatus == kCMBlockBufferNoErr && sampleBufferRef){
            VTDecodeFrameFlags frameFlags = 0;
            VTDecodeInfoFlags infoFlags = 0;
            
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decompressionSession,
                                                                      sampleBufferRef,
                                                                      frameFlags,
                                                                      NULL,
                                                                      &infoFlags);
            //kVTVideoDecoderBadDataErr
            if(decodeStatus != noErr){
                NSLog(@"YXDecoder VTDecompressionSessionDecodeFrame error: %d", (int)decodeStatus);
            }
            
            CFRelease(sampleBufferRef);
        }
        CFRelease(blockBufferRef);
    }
}
@end
