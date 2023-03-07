//
//  OmniRtcOrientation.h
//  MetalVideo
//
//  Created by yanzhen on 2021/4/1.
//

#import <UIKit/UIKit.h>
#import <simd/vector_types.h>

extern float *kOmniRtcColorConversion601;
extern float *kOmniRtcColorConversion601FullRange;
extern float *kOmniRtcColorConversion709;

typedef NS_ENUM(NSInteger, OmniRtcVideoOrientation) {
    OmniRtcVideoOrientationUnknown    = 0,
    OmniRtcVideoOrientationPortrait   = 1,
    OmniRtcVideoOrientationUpsideDown = 2,
    OmniRtcVideoOrientationLeft       = 3,
    OmniRtcVideoOrientationRight      = 4
};

@interface OmniRtcOrientation : NSObject
@property (nonatomic) OmniRtcVideoOrientation outputOrientation;
@property (nonatomic) BOOL mirror;

+ (simd_float8)defaultVertices;

+ (simd_float8)defaultTextureCoordinates;
+ (simd_float8)getTextureCoordinates:(int)rotation mirror:(BOOL)mirror;

@end

