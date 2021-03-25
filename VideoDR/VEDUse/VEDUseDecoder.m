//
//  VEDUseDecoder.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "VEDUseDecoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface VEDUseDecoder ()
@property (nonatomic) BOOL isKeyFrame;
@end

@implementation VEDUseDecoder {
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
    
}

@end
