//
//  RenderViewController.m
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import "RenderViewController.h"

@interface RenderViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *showPlayer;

@end

@implementation RenderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.redColor;
}

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
