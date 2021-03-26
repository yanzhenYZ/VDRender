//
//  YZLibVideoData.h
//  YZLibyuv
//
//  Created by yanzhen on 2021/3/3.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface YZLibVideoData : NSObject
@property (assign, nonatomic) CVPixelBufferRef pixelBuffer;

@property (nonatomic, assign) BOOL isNV12;

@property (strong, nonatomic) NSData *buffer;

@property (assign, nonatomic) int width;

@property (assign, nonatomic) int height;

@property (assign, nonatomic) int cropLeft;

@property (assign, nonatomic) int cropTop;

@property (assign, nonatomic) int cropRight;

@property (assign, nonatomic) int cropBottom;
/** 0, 90, 180, 270 */
@property (assign, nonatomic) int rotation;

@property (nonatomic) int yStride;
@property (nonatomic) int uStride;
@property (nonatomic) int vStride;
@property (nonatomic) int uvStride;

@property (nonatomic) int8_t *yBuffer;
@property (nonatomic) int8_t *uBuffer;
@property (nonatomic) int8_t *vBuffer;
@property (nonatomic) int8_t *uvBuffer;
@end


