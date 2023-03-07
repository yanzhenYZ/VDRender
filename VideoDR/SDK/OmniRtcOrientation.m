//
//  OmniRtcOrientation.m
//  MetalVideo
//
//  Created by yanzhen on 2021/4/1.
//

#import "OmniRtcOrientation.h"

float OmniRtcColorConversion601Default[] = {
    1.164, 1.164,  1.164, 0.0,
    0.0,   -0.392, 2.017, 0.0,
    1.596, -0.813, 0.0,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
float OmniRtcColorConversion601FullRangeDefault[] = {
    1.0, 1.0,    1.0,   0.0,
    0.0, -0.343, 1.765, 0.0,
    1.4, -0.711, 0.0,   0.0,
};

// BT.709, which is the standard for HDTV.
float OmniRtcColorConversion709Default[] = {
    1.164, 1.164,  1.164, 0.0,
    0.0,   -0.213, 2.112, 0.0,
    1.793, -0.533, 0.0,   0.0,
};


float *kOmniRtcColorConversion601 = OmniRtcColorConversion601Default;
float *kOmniRtcColorConversion601FullRange = OmniRtcColorConversion601FullRangeDefault;
float *kOmniRtcColorConversion709 = OmniRtcColorConversion709Default;

static const simd_float8 OmniRtcStandardVertices = {-1, 1, 1, 1, -1, -1, 1, -1};

static const simd_float8 OmniRtcNoRotation = {0, 0, 1, 0, 0, 1, 1, 1};
static const simd_float8 OmniRtcRotateCounterclockwise = {0, 1, 0, 0, 1, 1, 1, 0};
static const simd_float8 OmniRtcRotateClockwise = {1, 0, 1, 1, 0, 0, 0, 1};
static const simd_float8 OmniRtcRotate180 = {1, 1, 0, 1, 1, 0, 0, 0};
static const simd_float8 OmniRtcFlipHorizontally = {1, 0, 0, 0, 1, 1, 0, 1};
static const simd_float8 OmniRtcFlipVertically = {0, 1, 1, 1, 0, 0, 1, 0};
static const simd_float8 OmniRtcRotateClockwiseAndFlipVertically = {0, 0, 0, 1, 1, 0, 1, 1};
static const simd_float8 OmniRtcRotateClockwiseAndFlipHorizontally = {1, 1, 1, 0, 0, 1, 0, 0};

typedef NS_ENUM(NSInteger, OmniRtcRotation) {
    OmniRtcRotationNoRotation                         = 0,
    OmniRtcRotationRotate180                          = 1,
    OmniRtcRotationRotateCounterclockwise             = 2,
    OmniRtcRotationRotateClockwise                    = 3,
    OmniRtcRotationFlipHorizontally                   = 4,
    OmniRtcRotationFlipVertically                     = 5,
    OmniRtcRotationRotateClockwiseAndFlipVertically   = 6,
    OmniRtcRotationRotateClockwiseAndFlipHorizontally = 7
};

@interface OmniRtcOrientation ()
@property (nonatomic) OmniRtcVideoOrientation inputOrientation;
@end

@implementation OmniRtcOrientation
- (instancetype)init
{
    self = [super init];
    if (self) {
        _inputOrientation = OmniRtcVideoOrientationRight;
        _outputOrientation = OmniRtcVideoOrientationPortrait;
    }
    return self;
}

+ (simd_float8)defaultVertices {
    return OmniRtcStandardVertices;
}


+ (simd_float8)defaultTextureCoordinates {
    return OmniRtcNoRotation;
}

+ (simd_float8)getTextureCoordinates:(int)rotation mirror:(BOOL)mirror {
    switch (rotation) {
        case 0:
            if (mirror) {
                return OmniRtcFlipHorizontally;
            } else {
                return OmniRtcNoRotation;
            }
            break;
        case 90:
            if (mirror) {
                return OmniRtcRotateClockwiseAndFlipVertically;
            } else {
                return OmniRtcRotateCounterclockwise;
            }
            break;
        case 180:
            if (mirror) {
                return OmniRtcFlipVertically;
            } else {
                return OmniRtcRotate180;
            }
            break;
        case 270:
            if (mirror) {
                return OmniRtcRotateClockwiseAndFlipHorizontally;
            } else {
                return OmniRtcRotateClockwise;
            }
            break;
        default:
            break;
    }
    return OmniRtcNoRotation;
}


#pragma mark - orientation


@end

