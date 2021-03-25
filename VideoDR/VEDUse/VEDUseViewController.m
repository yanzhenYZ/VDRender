//
//  VEDUseViewController.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "VEDUseViewController.h"
#import "VEDUseEncoder.h"
#import "VEDUseDecoder.h"
#import "VEDUseCapture.h"
#import "YXLayerPlayer.h"

@interface VEDUseViewController ()<VEDUseCaptureDelegate, VEDUseEncoderDelegate, VEDUseDecoderDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *mainPlayer;
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;

@property (nonatomic, strong) YXLayerPlayer *player;

@property (nonatomic, strong) VEDUseEncoder *encoder;
@property (nonatomic, strong) VEDUseDecoder *decoder;
@property (nonatomic, strong) VEDUseCapture *capture;
@end

@implementation VEDUseViewController

- (void)dealloc
{
    [_encoder stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    YXLayerPlayer *player = [[YXLayerPlayer alloc] initWithFrame:self.showPlayer.bounds];
    player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.showPlayer addSubview:player];
    _player = player;
    
    
    _encoder = [[VEDUseEncoder alloc] init];
    _encoder.delegate = self;
    [_encoder startEncode:480 height:640];

    _decoder = [[VEDUseDecoder alloc] init];
    _decoder.delegate = self;
    
    _capture = [[VEDUseCapture alloc] initWithPlayer:_mainPlayer];
    _capture.delegate = self;
    [_capture startRunning];
}

#pragma mark - VEDUseDecoderDelegate
- (void)decoder:(VEDUseDecoder *)decoder didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [_player displayVideo:pixelBuffer];
}

#pragma mark - VEDUseEncoderDelegate
- (void)encoder:(VEDUseEncoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps {
    NSLog(@"SPS:%lu:%lu", (unsigned long)sps.length, (unsigned long)pps.length);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //发sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    //[_decoder decodeData:h264Data];
    
    //发pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    //[_decoder decodeData:h264Data];
}

- (void)encoder:(VEDUseEncoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey {
    NSLog(@"Data:%lu:%d", (unsigned long)data.length, isKey);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    //[_decoder decodeData:h264Data];
}

#pragma mark - VEDUseCaptureDelegate
- (void)capture:(VEDUseCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [_encoder encodePixelBuffer:pixelBuffer];
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
