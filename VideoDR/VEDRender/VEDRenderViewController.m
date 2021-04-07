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

#import <YZVideoRender/YZVideoRender.h>


#define MTK 1

@interface VEDRenderViewController ()<VEDRCaptureDelegate, VEDRDecoderDelegate, VEDREncoderDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *mainPlayer;
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;

#if MTK
@property (nonatomic, strong) YXSMKTView *player;
#else
@property (nonatomic, strong) YXLayerPlayer *player;
#endif

@property (nonatomic, strong) VEDREncoder *encoder;
@property (nonatomic, strong) VEDRDecoder *decoder;
@property (nonatomic, strong) VEDRCapture *capture;


@property (nonatomic, strong) YZVideoDisplay *display;
@end

@implementation VEDRenderViewController

- (void)dealloc
{
    [_encoder stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    _display = [[YZVideoDisplay alloc] init];
//    [_display setViewFillMode:YZVideoFillModeScaleAspectFit];
    [_display setVideoShowView:_showPlayer];
    
    _encoder = [[VEDREncoder alloc] init];
    _encoder.delegate = self;
    [_encoder startEncode:120 height:160];

    _decoder = [[VEDRDecoder alloc] init];
    _decoder.delegate = self;
    
    _capture = [[VEDRCapture alloc] initWithPlayer:_mainPlayer];
    _capture.delegate = self;
    [_capture startRunning];
}

- (IBAction)segment:(UISegmentedControl *)sender {
    [_display setViewFillMode:sender.selectedSegmentIndex];
}

#pragma mark - VEDRDecoderDelegate
-(void)decoder:(VEDRDecoder *)decoder didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer {
//    [_player displayVideo:pixelBuffer];
//    YZVideoData *data = [[YZVideoData alloc] init];
//    data.pixelBuffer = pixelBuffer;
//    [_display displayVideo:data];
    
//    [self testNV12:pixelBuffer];
    [self testI420:pixelBuffer];
}

- (void)testI420:(CVPixelBufferRef)pixelBuffer {
    YZVideoData *data = [[YZVideoData alloc] init];
    data.format = YZVideoFormatI420;
    data.width = (int)CVPixelBufferGetWidth(pixelBuffer);
    data.height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t *yBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *uBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    uint8_t *vBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    
    size_t yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    size_t uStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    size_t vStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);
    //uint8_t *yy = malloc(data.width * data.height);
//    for (int i = 0; i < data.height; i++) {
//        memcpy(yy + data.width * i, yBuffer + yStride * i, data.width);
//    }
    
    //data.yBuffer = yy;
    data.yBuffer = yBuffer;
    data.uBuffer = uBuffer;
    data.vBuffer = vBuffer;
    
//    data.yStride = data.width;
    data.yStride = yStride;
    data.uStride = uStride;
    data.vStride = vStride;
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [_display displayVideo:data];
//    free(yy);
}

- (void)testNV12:(CVPixelBufferRef)pixelBuffer {
    
    YZVideoData *data = [[YZVideoData alloc] init];
    data.format = YZVideoFormatNV12;
    data.width = (int)CVPixelBufferGetWidth(pixelBuffer);
    data.height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t *yBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *uvBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    size_t yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    size_t uvStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    
    data.yBuffer = yBuffer;
    data.uvBuffer = uvBuffer;
    
    data.yStride = yStride;
    data.uvStride = uvStride;
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [_display displayVideo:data];
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
@end
