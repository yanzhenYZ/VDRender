#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

typedef NS_ENUM(NSUInteger, YXVideoRotation) {
    YXVideoRotation0   = 0,
    YXVideoRotation90  = 90,
    YXVideoRotation180 = 180,
    YXVideoRotation270 = 270,
};

typedef NS_ENUM(NSUInteger, YXVideoFormat) {
    /** support 
     kCVPixelFormatType_32BGRA
     kCVPixelFormatType_420YpCbCr8Planar
     kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
     */
    YXVideoFormatPixelBuffer,
    /** I420 */
    YXVideoFormatI420,
    /** NV12 */
    YXVideoFormatNV12,
};

@interface YXVideoData : NSObject
/** see YXVideoFormat */
@property (nonatomic, assign) YXVideoFormat format;

/** see YXVideoFormat */
@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

/** input video width */
@property (nonatomic, assign) int width;

/** input video heigth */
@property (nonatomic, assign) int height;


/** crop video left */
@property (nonatomic, assign) int cropLeft;

/** crop video top */
@property (nonatomic, assign) int cropTop;

/** crop video right */
@property (nonatomic, assign) int cropRight;

/** crop video bottom */
@property (nonatomic, assign) int cropBottom;


/** set the video rotation degree */
@property (nonatomic, assign) YXVideoRotation rotation;

/** mirror */
@property (nonatomic, assign) BOOL mirror;


/** I420 or NV12 y stride */
@property (nonatomic, assign) int yStride;

/** I420 u stride */
@property (nonatomic, assign) int uStride;

/** I420 v stride */
@property (nonatomic, assign) int vStride;

/** NV12 uv stride */
@property (nonatomic, assign) int uvStride;


/** I420 or NV12 y buffer */
@property (nonatomic) int8_t *yBuffer;

/** I420 u buffer */
@property (nonatomic) int8_t *uBuffer;

/** I420 v buffer */
@property (nonatomic) int8_t *vBuffer;

/** NV12 uv buffer */
@property (nonatomic) int8_t *uvBuffer;
@end

