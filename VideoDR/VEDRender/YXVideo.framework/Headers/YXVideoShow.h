#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, YZVideoFillMode) {
    YZVideoFillModeScaleToFill,     /** Same as UIViewContentModeScaleToFill */
    YZVideoFillModeScaleAspectFit,  /** Same as UIViewContentModeScaleAspectFit */
    YZVideoFillModeScaleAspectFill, /** Same as UIViewContentModeScaleAspectFill */
};

@class YXVideoData;
@interface YXVideoShow : NSObject
/**
 *  isSupportAdditionalFeatures
 *  @abstract   The additional features contain YXVideoData's cropLeft, cropTop, cropRight, cropBottom, mirror and rotation.
 *
 *  @return     YES             The device is supported.
 *              NO              The device is not supported
 */
+ (BOOL)isSupportAdditionalFeatures;

- (void)setVideoShowView:(UIView *)view; //set video show view
- (void)setViewFillMode:(YZVideoFillMode)mode; //see YZVideoFillMode

- (void)displayVideo:(YXVideoData *)videoData; //show video
@end
