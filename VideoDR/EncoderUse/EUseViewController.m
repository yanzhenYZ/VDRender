//
//  EUseViewController.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import "EUseViewController.h"
#import "EUseH264HwEncoder.h"
#import "EncoderUseCapture.h"
#import "YXFileHandle.h"

@interface EUseViewController ()<EUseH264HwEncoderDelegate, EncoderUseCaptureDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;

@property (nonatomic, strong) EncoderUseCapture *capture;
@property (nonatomic, strong) EUseH264HwEncoder *encoder;
@property (nonatomic, strong) YXFileHandle *fileHandle;
@end

@implementation EUseViewController

- (void)dealloc
{
    [_fileHandle stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _encoder = [[EUseH264HwEncoder alloc] init];
    _encoder.delegate = self;
    [_encoder startEncode:480 height:640];
    
    _fileHandle = [[YXFileHandle alloc] init];
    
    _capture = [[EncoderUseCapture alloc] initWithPlayer:_showPlayer];
    _capture.delegate = self;
    [_capture startRunning];
}

#pragma mark - EncoderUseCaptureDelegate
- (void)capture:(EncoderUseCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [_encoder encodePixelBuffer:pixelBuffer];
}

#pragma mark - EUseH264HwEncoderDelegate
- (void)encoder:(EUseH264HwEncoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps {
    //NSLog(@"SPS:%lu:%lu", (unsigned long)sps.length, (unsigned long)pps.length);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //发sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    [_fileHandle writeData:h264Data];
    
    //发pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    [_fileHandle writeData:h264Data];
}

- (void)encoder:(EUseH264HwEncoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey {
    //NSLog(@"Data:%lu:%d", (unsigned long)data.length, isKey);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    [_fileHandle writeData:h264Data];
}

#pragma mark - ui
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