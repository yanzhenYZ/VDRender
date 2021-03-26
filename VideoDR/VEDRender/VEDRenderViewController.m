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


#import "WXSDLGLView_RTC.h"

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

@implementation VEDRenderViewController

- (void)dealloc
{
    [_encoder stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [YXMetalManager manager];
    
    _renderView = [[WXSDLGLView alloc] initWithFrame:self.showPlayer.bounds withCropFrame:nil];
    _renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.showPlayer addSubview:_renderView];
#if MTK
//    _player = [[YXSMKTView alloc] initWithFrame:self.showPlayer.bounds];
//    _player = [[YXYMTKView alloc] initWithFrame:self.showPlayer.bounds];
//    _player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.showPlayer addSubview:_player];
#else
    YXLayerPlayer *player = [[YXLayerPlayer alloc] initWithFrame:self.showPlayer.bounds];
    player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.showPlayer addSubview:player];
    _player = player;
#endif
    
    _encoder = [[VEDREncoder alloc] init];
    _encoder.delegate = self;
    [_encoder startEncode:320 height:240];

    _decoder = [[VEDRDecoder alloc] init];
    _decoder.delegate = self;
    
    _capture = [[VEDRCapture alloc] initWithPlayer:_mainPlayer];
    _capture.delegate = self;
    [_capture startRunning];
}

#pragma mark - VEDRDecoderDelegate
-(void)decoder:(VEDRDecoder *)decoder didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    
//    [_player displayVideo:pixelBuffer];
    [self diiplay:pixelBuffer];
    
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
    } else {//==
        data.yBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        data.uBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        data.vBuffer = (int8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [_renderView displayData:data];
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
