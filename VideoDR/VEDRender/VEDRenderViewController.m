//
//  VEDRenderViewController.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "VEDRenderViewController.h"
#import "YXSMKTView.h"
#import "YXLayerPlayer.h"
#import "VEDRCapture.h"
#import "VEDREncoder.h"
#import "VEDRDecoder.h"
#import "YXMetalManager.h"

#import "YXYMTKView.h"
#import "YXDMTKView.h"
#import "YXNMTKView.h"
#import <YZLibyuv/YZLibyuv.h>


//#import "WXSDLGLView_RTC.h"
#import <WXVPlayer/WXVPlayer.h>

#define MTK 1

@interface VEDRenderViewController ()<VEDRCaptureDelegate, VEDRDecoderDelegate, VEDREncoderDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *mainPlayer;
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;

#if MTK
//@property (nonatomic, strong) YXSMKTView *player;
//@property (nonatomic, strong) YXDMTKView *player;
//@property (nonatomic, strong) YXNMTKView *player;
@property (nonatomic, strong) YXYMTKView *player;
#else
@property (nonatomic, strong) YXLayerPlayer *player;
#endif

@property (nonatomic, strong) VEDREncoder *encoder;
@property (nonatomic, strong) VEDRDecoder *decoder;
@property (nonatomic, strong) VEDRCapture *capture;


@property (nonatomic, strong) WXSDLGLView *renderView;
@end

@implementation VEDRenderViewController {
    CVPixelBufferRef _pixelBuffer;
}

- (void)dealloc
{
    [_encoder stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [YXMetalManager manager];
#if 1
    _renderView = [[WXSDLGLView alloc] initWithFrame:self.showPlayer.bounds withCropFrame:nil];
    _renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _renderView.contentMode = UIViewContentModeScaleAspectFit;
    [self.showPlayer addSubview:_renderView];
#else
    _player = [[YXYMTKView alloc] initWithFrame:self.showPlayer.bounds];
    _player = [[YXYMTKView alloc] initWithFrame:self.showPlayer.bounds];
    _player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.showPlayer addSubview:_player];
#endif
//#if MTK
//    _player = [[YXSMKTView alloc] initWithFrame:self.showPlayer.bounds];
//    _player = [[YXYMTKView alloc] initWithFrame:self.showPlayer.bounds];
//    _player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.showPlayer addSubview:_player];
//#else
//    YXLayerPlayer *player = [[YXLayerPlayer alloc] initWithFrame:self.showPlayer.bounds];
//    player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.showPlayer addSubview:player];
//    _player = player;
//#endif
    
    _encoder = [[VEDREncoder alloc] init];
    _encoder.delegate = self;
    /** nv12Render             bgraToNV12
     120x120           有绿边   =
     160x120  120x160  有绿边   =
     180x180                   =
     240x180  180x240          =
     320x180  180x320          =
     240x240                   =
     320x240  240x320          =
     424x240  240x424          =
     360x360                   =
     480x360 360x480           =
     640x360 360x640           =
     480x480                   =
     640x480 480x640           =
     840x480 480x840           =
     960x720 720x960           =
     1280x720 720x1280         =
     */
    [_encoder startEncode:1280 height:720];

    _decoder = [[VEDRDecoder alloc] init];
    _decoder.delegate = self;
    
    _capture = [[VEDRCapture alloc] initWithPlayer:_mainPlayer];
    _capture.delegate = self;
    [_capture startRunning];
}

#pragma mark - VEDRDecoderDelegate
-(void)decoder:(VEDRDecoder *)decoder didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    
    //[_player displayVideo:pixelBuffer];
    
    //[self diiplay:pixelBuffer];
    
    //[self nv12Render:pixelBuffer];
    
    [self bgraToNV12:pixelBuffer];
}


- (void)bgraToNV12:(CVPixelBufferRef)pixelBuffer {
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    [self dealPixelBuffer:CGSizeMake(width, height)];
    if (!_pixelBuffer) {
        NSLog(@"Error:CVPixelBuffer");
        return;
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t *bgra = CVPixelBufferGetBaseAddress(pixelBuffer);
    int bgraStride = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(_pixelBuffer, 0);
    
    uint8_t *y = CVPixelBufferGetBaseAddressOfPlane(_pixelBuffer, 0);
    int strideY = CVPixelBufferGetBytesPerRowOfPlane(_pixelBuffer, 0);
    uint8_t *uv = CVPixelBufferGetBaseAddressOfPlane(_pixelBuffer, 1);
    int strideUV = CVPixelBufferGetBytesPerRowOfPlane(_pixelBuffer, 1);
    
    [YZLibyuv BGRAToNV12:bgra bgraStride:bgraStride dstY:y strideY:strideY dstUV:uv strideUV:strideUV width:width height:height];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
    [self nv12Render:_pixelBuffer];
}

- (void)dealPixelBuffer:(CGSize)size {
    if (_pixelBuffer) {
        if (CVPixelBufferGetWidth(_pixelBuffer) == size.width || CVPixelBufferGetHeight(_pixelBuffer) == size.height) {
            return;
        }
        if (_pixelBuffer) {
            CVPixelBufferRelease(_pixelBuffer);
            _pixelBuffer = nil;
        }
    }
    NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                            size.width,
                                            size.height,
                                            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                            (__bridge CFDictionaryRef)(pixelAttributes),
                                            &_pixelBuffer);
    if (result != kCVReturnSuccess) {
        NSLog(@"PixelBuffer to create cvpixelbuffer %d", result);
        return;
    }
}

- (void)nv12Render:(CVPixelBufferRef)pixelBuffer {
    [_renderView displayNv12:pixelBuffer rotation:0];
}

- (void)bgraRender:(CVPixelBufferRef)pixelBuffer {
    //不是RGBA-渲染有问题
    [_renderView displayBgra:pixelBuffer];
}

- (void)diiplay:(CVPixelBufferRef)pixelBuffer {
    YXVideoData *data = [YXVideoData new];
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    data.width = width;
    data.height = height;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    data.yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    data.uStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    data.vStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);
    //NSLog(@"__%d:%d:%d:%d", data.width, data.height, data.yStride, data.uStride);
#if 0
    data.yBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    data.uBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    data.vBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [_renderView displayData:data];
#else
    if (data.uStride * 2 > data.yStride) {//todo 320x240横屏
        int a = (data.uStride - data.yStride / 2) / 2;
        data.uStride = data.yStride / 2;
        data.vStride = data.uStride;
        int8_t *yBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        int8_t *uBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        int8_t *vBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
        data.yBuffer = yBuffer;
        
        data.uBuffer = uBuffer;
        data.vBuffer = vBuffer;

        
        int len = data.uStride * data.height / 2;
        int8_t *newUBuffer = malloc(len);
        int8_t *newVBuffer = malloc(len);
        int stride = data.uStride;
        int uByytesPerrow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
        for (int i = 0; i < data.height / 2; i++) {
            memcpy(newUBuffer + stride * i, uBuffer + uByytesPerrow * i, stride);
            memcpy(newVBuffer + stride * i, vBuffer + uByytesPerrow * i, stride);
        }

        data.uBuffer = newUBuffer;
        data.vBuffer = newVBuffer;
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        [_renderView displayData:data];
        free(newUBuffer);
        free(newVBuffer);
    } else {//==
        data.yBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        data.uBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        data.vBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        [_renderView displayData:data];
    }
    
#endif
    
}

#pragma mark - VEDREncoderDelegate
- (void)encoder:(VEDREncoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps {
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //发sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    [_decoder decodeData:h264Data];
    
    //发pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    [_decoder decodeData:h264Data];
}

- (void)encoder:(VEDREncoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey {
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    [_decoder decodeData:h264Data];
}

#pragma mark - VEDRCaptureDelegate
- (void)capture:(VEDRCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [self.encoder encodePixelBuffer:pixelBuffer];
}

#pragma mark - UI
- (IBAction)exitCapture:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

//add test
-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft;
}
@end
