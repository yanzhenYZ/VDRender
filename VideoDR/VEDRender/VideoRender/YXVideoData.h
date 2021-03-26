//
//  YXVideoData.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/26.
//

#import <Foundation/Foundation.h>

@interface YXVideoData : NSObject
@property (assign, nonatomic) int width;
@property (assign, nonatomic) int height;
@property (nonatomic) int yStride;
@property (nonatomic) int uStride;
@property (nonatomic) int vStride;
@property (nonatomic) int8_t *yBuffer;
@property (nonatomic) int8_t *uBuffer;
@property (nonatomic) int8_t *vBuffer;

@end


