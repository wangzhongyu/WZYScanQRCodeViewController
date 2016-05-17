//
//  WZYScanQRCodeViewController.h
//  WZYScanQRCodeDemo
//
//  Created by 王中雨 on 16/5/17.
//  Copyright © 2016年 王中雨. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ScanQRCodeResultHandler)(NSString *result, NSError *error);

@interface WZYScanQRCodeViewController : UIViewController

@property (nonatomic, copy) ScanQRCodeResultHandler completionHandler;

+ (BOOL)isAvailable;

@end
