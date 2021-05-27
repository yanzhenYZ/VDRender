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

#import <YXVideo/YXVideo.h>


#define MTK 1

@interface VEDRenderViewController ()<VEDRCaptureDelegate, VEDRDecoderDelegate, VEDREncoderDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *mainPlayer;
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;

#if MTK
@property (nonatomic, strong) YXSMKTView *player;
#else
@property (nonatomic, strong) YXLayerPlayer *player;
#endif

@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, assign) CGSize size;

@property (nonatomic, strong) VEDREncoder *encoder;
@property (nonatomic, strong) VEDRDecoder *decoder;
@property (nonatomic, strong) VEDRCapture *capture;

@property (nonatomic, assign) BOOL mirror;

@property (nonatomic, strong) YXVideoShow *display;
@end

/**
 YX001: 支持附加功能
 YX002: 切换显示视图
 YX003: 显示模式
 
 YX004: YXVideoFormatPixelBuffer
 YX005: YXVideoFormatI420
 YX006: YXVideoFormatNV12
 YX007: crop
 YX008: rotation
 YX009: mirror
 
 YX0010: 中途切换format
 
 */


@implementation VEDRenderViewController

- (void)dealloc
{
    [_encoder stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
#pragma mark - YX001
//    NSLog(@"_____YX001:%d", [YXVideoShow isSupportAdditionalFeatures]);
//
    _display = [[YXVideoShow alloc] init];
    [_display setViewFillMode:YXVideoFillModeScaleAspectFit];
    [_display setVideoShowView:_showPlayer];
    
    _size = CGSizeMake(1280, 720);
    [self resetEncoder];

    _decoder = [[VEDRDecoder alloc] init];
    _decoder.type = 1;
#pragma mark - YX004 -- 类型
//    _decoder.type = 1;//0,1,2,3

#pragma mark - YX005 -- must type = 3
//    _decoder.type = 3;

#pragma mark - YX006 -- must type = 1 or 2
//    _decoder.type = 1;
    
    
    _lock = [[NSLock alloc] init];
//    _player = [[YXSMKTView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:_player];
//    
    _decoder.delegate = self;
    
    _capture = [[VEDRCapture alloc] initWithPlayer:_mainPlayer];
    _capture.delegate = self;
    [_capture startRunning];
    
//    [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        [self resetEncoder];
//    }];
}

- (void)resetEncoder {
    [_lock lock];
    [_encoder stop];
    _encoder = nil;
    
    _size = CGSizeMake(_size.height, _size.width);
    
    _encoder = [[VEDREncoder alloc] init];
    _encoder.delegate = self;
    [_encoder startEncode:_size.width height:_size.height];
    [_lock unlock];
}

- (IBAction)segment:(UISegmentedControl *)sender {
    //[self setFillMode:sender.selectedSegmentIndex];
    //return;
    
#pragma mark - YX0010
//    if (sender.selectedSegmentIndex == 0) {
//        _decoder = [[VEDRDecoder alloc] init];
//        _decoder.type = 3;
//        _decoder.delegate = self;
//    } else if (sender.selectedSegmentIndex == 1) {
//        _decoder = [[VEDRDecoder alloc] init];
//        _decoder.type = 1;
//        _decoder.delegate = self;
//    } else {
//        _decoder = [[VEDRDecoder alloc] init];
//        _decoder.type = 0;
//        _decoder.delegate = self;
//    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //[self switchShowView];
    
    _mirror = !_mirror;
}

#pragma mark - YX003
- (void)setFillMode:(YXVideoFillMode)mode {
    [_display setViewFillMode:mode];
}

#pragma mark - YX002
- (void)switchShowView {
    if (self.showPlayer.subviews.count > 0) {
        [_display setVideoShowView:_mainPlayer];
    } else {
        [_display setVideoShowView:_showPlayer];
    }
}

#pragma mark - VEDRDecoderDelegate
-(void)decoder:(VEDRDecoder *)decoder didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer {
//    [_player displayVideo:pixelBuffer];
    [self displayPixelBuffer:pixelBuffer];
    
    
    
    
    
    
    
    
    
    //[self displayI420:pixelBuffer];
    
    //[self displayNV12:pixelBuffer];
    
#pragma mark - YX0010
//    OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
//    if (type == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
//        [self displayNV12:pixelBuffer];
//        NSLog(@"xxx001");
//    } else if (type == kCVPixelFormatType_420YpCbCr8Planar) {
//        [self displayI420:pixelBuffer];
//        NSLog(@"xxx002");
//    } else {
//        NSLog(@"xxx003");
//        [self displayPixelBuffer:pixelBuffer];
//    }
}

#pragma mark - YX006
- (void)displayNV12:(CVPixelBufferRef)pixelBuffer {
    
    YXVideoData *data = [[YXVideoData alloc] init];
    data.format = YXVideoFormatNV12;
    data.width = (int)CVPixelBufferGetWidth(pixelBuffer);
    data.height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int8_t *yBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    int8_t *uvBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    size_t yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    size_t uvStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    
    data.yBuffer = yBuffer;
    data.uvBuffer = uvBuffer;
    
    data.yStride = (int)yStride;
    data.uvStride = (int)uvStride;
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [_display displayVideo:data];
}

#pragma mark - YX005
- (void)displayI420:(CVPixelBufferRef)pixelBuffer {
    YXVideoData *data = [[YXVideoData alloc] init];
    data.format = YXVideoFormatI420;
    
#pragma mark - YX007
//    data.cropTop = 140;
//    data.cropBottom = 140;
    
    
#pragma mark - YX008
//    data.rotation = 180;
    
#pragma mark - YX009
//    data.mirror = _mirror;
    
    data.width = (int)CVPixelBufferGetWidth(pixelBuffer);
    data.height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int8_t *yBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    int8_t *uBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    int8_t *vBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    
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
    data.yStride = (int)yStride;
    data.uStride = (int)uStride;
    data.vStride = (int)vStride;
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [_display displayVideo:data];
}

#pragma mark - YX004
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    YXVideoData *data = [[YXVideoData alloc] init];
    data.format = YXVideoFormatPixelBuffer;
    data.pixelBuffer = pixelBuffer;
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
//    NSLog(@"123");
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
    [_lock lock];
    [self.encoder encodePixelBuffer:pixelBuffer];
    [_lock unlock];
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
