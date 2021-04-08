#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, YXVideoFillMode) {
    YXVideoFillModeScaleToFill,     /** Same as UIViewContentModeScaleToFill */
    YXVideoFillModeScaleAspectFit,  /** Same as UIViewContentModeScaleAspectFit */
    YXVideoFillModeScaleAspectFill, /** Same as UIViewContentModeScaleAspectFill */
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
- (void)setViewFillMode:(YXVideoFillMode)mode; //see YXVideoFillMode

- (void)displayVideo:(YXVideoData *)videoData; //show video
@end
