//
//  VEDRNote.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

/** iPhone6s 640x480 10fps
 采集kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
 
 不渲染：初始化对象YXLayerPlayer
    解码
    kCVPixelFormatType_32BGRA                      3% 21MB
    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 3% 20.9MB
    kCVPixelFormatType_420YpCbCr8Planar            3% 21MB
 
  渲染AVSampleBufferDisplayLayer
    解码
    kCVPixelFormatType_32BGRA                      4% 21MB
    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 4% 20.9MB
    kCVPixelFormatType_420YpCbCr8Planar            4% 21MB
 
  渲染YXSMKTView
    解码
    kCVPixelFormatType_32BGRA                      5% 27.9MB
 
 */


/** iPhone6s 1280x720 10fps
 采集kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
 
 不渲染：初始化对象YXLayerPlayer
    解码
    kCVPixelFormatType_32BGRA                      4% 35.2MB YXSMKTView=35.8MB
    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 4% 35MB
    kCVPixelFormatType_420YpCbCr8Planar            4% 35MB
 
  渲染AVSampleBufferDisplayLayer
    解码
    kCVPixelFormatType_32BGRA                      5% 35.2MB
    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 5% 35.2MB
    kCVPixelFormatType_420YpCbCr8Planar            5% 35.2MB
 
  渲染YXSMKTView
    解码
    kCVPixelFormatType_32BGRA                      5% 47.4MB
 
 */


/** iPhone6s 1280x720 10fps
 采集kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
 
  渲染AVSampleBufferDisplayLayer
    解码
    kCVPixelFormatType_32BGRA                      5% 35.2MB
    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 5% 35.2MB
    kCVPixelFormatType_420YpCbCr8Planar            5% 35.2MB
 
  
    解码
    kCVPixelFormatType_32BGRA                      渲染YXDMTKView 6% 52.5MB
    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 渲染YXDMTKView 6% 52MB
    kCVPixelFormatType_420YpCbCr8Planar            渲染YXYMTKView 6% 50.2MB
 */


/** iPhone6s 1280x720 10fps
 采集kCVPixelFormatType_420YpCbCr8BiPlanarFullRange

       解码
       kCVPixelFormatType_32BGRA                      渲染YXDMTKView 6% 52.5MB
Libyuv kCVPixelFormatType_32BGRA                      渲染YXDMTKView 9% 52.5MB
 */
