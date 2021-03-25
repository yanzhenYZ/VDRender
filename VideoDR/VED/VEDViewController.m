//
//  VEDViewController.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "VEDViewController.h"
#import "VEDH264Encoder.h"
#import "VEDH264Decoder.h"
#import "VEDCapture.h"
#import "YXLayerPlayer.h"

@interface VEDViewController ()<VEDCaptureDelegate, VEDH264EncoderDelegate, VEDH264DecoderDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *mainPlayer;
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;

@property (nonatomic, strong) YXLayerPlayer *player;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) VEDH264Encoder *encoder;
@property (nonatomic, strong) VEDH264Decoder *decoder;
@property (nonatomic, strong) VEDCapture *capture;
@end

@implementation VEDViewController

- (void)dealloc
{
    [_lock lock];
    _encoder = nil;
    [_lock unlock];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    YXLayerPlayer *player = [[YXLayerPlayer alloc] initWithFrame:self.showPlayer.bounds];
    player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.showPlayer addSubview:player];
    _player = player;
    
    _lock = [[NSLock alloc] init];
    _encoder = [[VEDH264Encoder alloc] init];
    _encoder.delegate = self;
    [_encoder startEncode:480 height:640];
    
    _decoder = [[VEDH264Decoder alloc] init];
    _decoder.delegate = self;
    
    _capture = [[VEDCapture alloc] initWithPlayer:_mainPlayer];
    _capture.delegate = self;
    [_capture startRunning];
}

#pragma mark - VEDH264DecoderDelegate
- (void)decoder:(VEDH264Decoder *)decoder didOutputSampleBuffer:(CMSampleBufferRef)sample {
    [_player displayBuffer:sample];
}

#pragma mark - VEDCaptureDelegate
- (void)capture:(VEDCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [_lock lock];
    [_encoder encodePixelBuffer:pixelBuffer];
    [_lock unlock];
}

#pragma mark - VEDH264EncoderDelegate
- (void)encoder:(VEDH264Encoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps {
    //NSLog(@"SPS:%lu:%lu", (unsigned long)sps.length, (unsigned long)pps.length);
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

- (void)encoder:(VEDH264Encoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey {
    //NSLog(@"Data:%lu:%d", (unsigned long)data.length, isKey);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    [_decoder decodeData:h264Data];
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
