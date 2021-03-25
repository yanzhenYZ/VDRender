//
//  VEDCapture.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#import "VEDCapture.h"
#import <AVFoundation/AVFoundation.h>

@interface VEDCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) UIView *player;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t dataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureConnection *connect;
@end

@implementation VEDCapture
- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    NSLog(@"VEDCapture---dealloc");
}

- (instancetype)initWithPlayer:(UIView *)player {
    self = [super init];
    if (self) {
        _player = player;
        [self configSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarDidChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)startRunning {
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
}

- (void)stopRunning {
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if ([_delegate respondsToSelector:@selector(capture:pixelBuffer:)]) {
        [_delegate capture:self pixelBuffer:pixelBuffer];
    }
}

#pragma mark - helper
- (void)configSession {
    _session = [[AVCaptureSession alloc] init];
    __block AVCaptureDevice *camera = nil;
    NSArray<AVCaptureDevice *> *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    [devices enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.position == AVCaptureDevicePositionFront) {
            camera = obj;
            *stop = YES;
        }
    }];
    if (camera == nil) {
        NSLog(@"未找到前置摄像头");
        return;
    }
    
    NSError *error;
    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    if (error) {
        NSLog(@"1234:%@",error.description);
        return;
    }
    
    _dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    _dataOutput.alwaysDiscardsLateVideoFrames = YES;
    //kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    _dataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    _dataOutputQueue = dispatch_queue_create("yz.video.queue", 0);
    [self.dataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
    if ([self.session canAddInput:self.deviceInput]) {
        [self.session addInput:self.deviceInput];
    }
    
    if ([self.session canAddOutput:self.dataOutput]) {
        [self.session addOutput:self.dataOutput];
    }
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    previewLayer.frame = UIScreen.mainScreen.bounds;
    [_player.layer addSublayer:previewLayer];
    
    self.session.sessionPreset = AVCaptureSessionPreset640x480;

    [_session beginConfiguration];
    _connect = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];
    [_connect setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [_session commitConfiguration];
    
    [camera lockForConfiguration:nil];
    camera.activeVideoMinFrameDuration = CMTimeMake(1, 10);
    camera.activeVideoMaxFrameDuration = CMTimeMake(1, 10);
    [camera unlockForConfiguration];
}

- (void)statusBarDidChanged:(NSNotification *)note {
    _player.layer.sublayers[0].frame = UIScreen.mainScreen.bounds;
}
@end
