#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

typedef NS_ENUM(NSUInteger, YZVideoRotation) {
    YZVideoRotation0   = 0,
    YZVideoRotation90  = 90,
    YZVideoRotation180 = 180,
    YZVideoRotation270 = 270,
};

typedef NS_ENUM(NSUInteger, YZVideoFormat) {
    /** support 
     kCVPixelFormatType_32BGRA
     kCVPixelFormatType_420YpCbCr8Planar
     kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
     */
    YZVideoFormatPixelBuffer,
    /** I420 */
    YZVideoFormatI420,
    /** NV12 */
    YZVideoFormatNV12,
};

@interface YZVideoData : NSObject
/** see YZVideoFormat */
@property (nonatomic, assign) YZVideoFormat format;

/** see YZVideoFormat */
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
@property (nonatomic, assign) YZVideoRotation rotation;

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

