//
//  EncoderViewController.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import "EncoderViewController.h"
#import "EncoderCapture.h"
#import "H264HwEncoder.h"

@interface EncoderViewController ()<EncoderCaptureDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;
@property (nonatomic, strong) EncoderCapture *capture;
@end

@implementation EncoderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _capture = [[EncoderCapture alloc] initWithPlayer:_showPlayer];
    _capture.delegate = self;
    [_capture startRunning];
}

#pragma mark - EncoderCaptureDelegate
- (void)capture:(EncoderCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer {
    NSLog(@"%d:%d", CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
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
