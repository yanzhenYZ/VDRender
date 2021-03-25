//
//  VEDRNote.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

/** iPhone6s 640x480
 采集kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
 
 不渲染：
    解码
    kCVPixelFormatType_32BGRA                      3% 21MB
    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 3% 20.9MB
    kCVPixelFormatType_420YpCbCr8Planar            3% 21MB
 
  渲染AVSampleBufferDisplayLayer
    解码
    kCVPixelFormatType_32BGRA                      4%    21MB
    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 4% 20.9MB
    kCVPixelFormatType_420YpCbCr8Planar            4% 21MB
 */
