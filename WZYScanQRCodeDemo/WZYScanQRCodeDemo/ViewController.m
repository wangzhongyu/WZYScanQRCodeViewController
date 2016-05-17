//
//  ViewController.m
//  WZYScanQRCodeDemo
//
//  Created by 王中雨 on 16/5/17.
//  Copyright © 2016年 王中雨. All rights reserved.
//

#import "ViewController.h"
#import "WZYScanQRCodeViewController/WZYScanQRCodeViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 100) * 0.5, ([UIScreen mainScreen].bounds.size.height - 40) * 0.5, 100, 40);
    [button setTitle:@"扫一扫" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(scan:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scan:(id)sender {
    if (![WZYScanQRCodeViewController isAvailable]) {
        return;
    }
    WZYScanQRCodeViewController *scanQRCodeViewController = [[WZYScanQRCodeViewController alloc] init];
    scanQRCodeViewController.completionHandler = ^(NSString *result, NSError *error) {
        if (result) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:result delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles:nil, nil];
            [alertView show];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:error.localizedDescription delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles:nil, nil];
            [alertView show];
        }
        [self dismissViewControllerAnimated:true completion:nil];
    };
    [self presentViewController:scanQRCodeViewController animated:true completion:nil];
}

@end
