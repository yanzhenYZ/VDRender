//
//  EncoderViewController.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import "EncoderViewController.h"
#import "EncoderCapture.h"
#import "H264HwEncoder.h"

@interface EncoderViewController ()<EncoderCaptureDelegate, H264HwEncoderDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;

@property (nonatomic, strong) EncoderCapture *capture;
@property (nonatomic, strong) H264HwEncoder *encoder;
@end

@implementation EncoderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _encoder = [[H264HwEncoder alloc] init];
    _encoder.delegate = self;
    [_encoder startEncode:480 height:640];
    
    _capture = [[EncoderCapture alloc] initWithPlayer:_showPlayer];
    _capture.delegate = self;
    [_capture startRunning];
}

#pragma mark - EncoderCaptureDelegate
- (void)capture:(EncoderCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer {
    //NSLog(@"%d:%d", CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    [_encoder encodePixelBuffer:pixelBuffer];
}

#pragma mark - H264HwEncoderDelegate
- (void)encoder:(H264HwEncoder *)encoder sendSps:(NSData *)sps pps:(NSData *)pps {
    NSLog(@"SPS:%lu:%lu", (unsigned long)sps.length, (unsigned long)pps.length);
}

- (void)encoder:(H264HwEncoder *)encoder sendData:(NSData *)data isKeyFrame:(BOOL)isKey {
    NSLog(@"Data:%lu:%d", (unsigned long)data.length, isKey);
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
