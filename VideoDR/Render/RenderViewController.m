//
//  RenderViewController.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import "RenderViewController.h"
#import "RenderCapture.h"

@interface RenderViewController ()<RenderCaptureDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;
@property (nonatomic, strong) RenderCapture *capture;
@end

@implementation RenderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _capture = [[RenderCapture alloc] initWithPlayer:_showPlayer];
    _capture.delegate = self;
    [_capture startRunning];
}

#pragma mark - RenderCaptureDelegate
- (void)capture:(RenderCapture *)capture pixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
}

#pragma mark - ui
- (IBAction)exitCapture:(UIButton *)sender {
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
