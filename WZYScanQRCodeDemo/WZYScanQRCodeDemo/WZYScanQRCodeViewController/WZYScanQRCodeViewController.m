//
//  WZYScanQRCodeViewController.m
//  WZYScanQRCodeDemo
//
//  Created by 王中雨 on 16/5/17.
//  Copyright © 2016年 王中雨. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "WZYScanQRCodeViewController.h"

@interface WZYScanQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;//媒体（音、视频）捕获会话，负责把捕获的音视频数据输出到输出设备中。一个AVCaptureSession可以有多个输入输出

@property (nonatomic, strong) AVCaptureDevice *captureDevice;//输入设备，包括麦克风、摄像头，通过该对象可以设置物理设备的一些属性（例如相机聚焦、白平衡等）

@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;//设备输入数据管理对象，可以根据AVCaptureDevice创建对应的AVCaptureDeviceInput对象，该对象将会被添加到AVCaptureSession中管理

@property (nonatomic, strong) AVCaptureMetadataOutput *captureMetadataOutput;//AVCaptureOutput：输出数据管理对象，用于接收各类输出数据，通常使用对应的子类AVCaptureAudioDataOutput、AVCaptureStillImageOutput、AVCaptureVideoDataOutput、AVCaptureFileOutput，该对象将会被添加到AVCaptureSession中管理。注意：前面几个对象的输出数据都是NSData类型，而AVCaptureFileOutput代表数据以文件形式输出，类似的，AVCcaptureFileOutput也不会直接创建使用，通常会使用其子类：AVCaptureAudioFileOutput、AVCaptureMovieFileOutput

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层，是CALayer的子类，使用该对象可以实时查看拍照或视频录制效果，创建该对象需要指定对应的AVCaptureSession对象

@property (nonatomic, strong) UIView *scanView;

@end

@implementation WZYScanQRCodeViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupBackButton];
    if (self.scanSize.width == 0 || self.scanSize.height == 0) {
        self.scanSize = CGSizeMake(200, 200);
    }
    if ([WZYScanQRCodeViewController isAvailable]) {
        [self setupConfiguration];
        [self setupScanView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.captureSession startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.captureSession stopRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - private
- (void)setupBackButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(20, 30, 40, 40);
    [button setTitle:@"back" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)setupScanView {
    self.scanView = [[UIView alloc] initWithFrame:[self scanRect]];
    self.scanView.layer.borderColor = [UIColor greenColor].CGColor;
    self.scanView.layer.borderWidth = 1.0;
    [self.view addSubview:self.scanView];
}

- (void)setupConfiguration {
    self.captureSession = [[AVCaptureSession alloc] init];
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
    NSError *error = nil;
    self.captureDevice = [self getCaptureDeviceWithPosition:AVCaptureDevicePositionBack];
    if (!self.captureDevice) {
        NSLog(@"取得后置摄像头时出现问题.");
        if (self.completionHandler) {
            error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.AVCaptureDevice.AVCaptureDevicePositionBack", NSStringFromClass(self.class)] code:0 userInfo:@{NSLocalizedDescriptionKey: @"取得后置摄像头时出现问题."}];
            self.completionHandler(nil, error);
        }
        return;
    }
    
    self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        if (self.completionHandler) {
            self.completionHandler(nil, error);
        }
        return;
    }
    
    self.captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //将设备输入添加到会话中
    if ([self.captureSession canAddInput:self.captureDeviceInput]) {
        [self.captureSession addInput:self.captureDeviceInput];
    }
    
    //将设备输出添加到会话中
    if ([self.captureSession canAddOutput:self.captureMetadataOutput]) {
        [self.captureSession addOutput:self.captureMetadataOutput];
        //设置输出的格式
        //一定要先设置会话的输出为output之后，再指定输出的元数据类型
        self.captureMetadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        //设置扫描区域
        self.captureMetadataOutput.rectOfInterest = CGRectMake([self scanRect].origin.y / [UIScreen mainScreen].bounds.size.height, [self scanRect].origin.x / [UIScreen mainScreen].bounds.size.width, self.scanSize.height / [UIScreen mainScreen].bounds.size.height, self.scanSize.width / [UIScreen mainScreen].bounds.size.width);
    }
    
    self.captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.captureVideoPreviewLayer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:self.captureVideoPreviewLayer atIndex:0];
}

#pragma mark - even respoder
- (void)back {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:true];
    } else {
        [self dismissViewControllerAnimated:true completion:^{}];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects == nil || metadataObjects.count == 0) {
        return;
    }
    [self.captureSession stopRunning];
    AVMetadataObject *metadataObject = metadataObjects[0];
    if ([metadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
        AVMetadataMachineReadableCodeObject *metadataObj = (AVMetadataMachineReadableCodeObject *)metadataObject;
        if (self.completionHandler) {
            self.completionHandler(metadataObj.stringValue, nil);
        }
    }
}

#pragma mark - getter
- (AVCaptureDevice *)getCaptureDeviceWithPosition:(AVCaptureDevicePosition )position {
    NSArray *captureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *captureDevice in captureDevices) {
        if (captureDevice.position == position) {
            return captureDevice;
        }
    }
    return nil;
}

- (CGRect)scanRect {
    return CGRectMake(([UIScreen mainScreen].bounds.size.width - self.scanSize.width) * 0.5, ([UIScreen mainScreen].bounds.size.height - self.scanSize.height) * 0.5, self.scanSize.width, self.scanSize.height);
}

#pragma mark -
+ (BOOL)isAvailable {
    __block BOOL flag = false;
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined: {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);//创建一个信号量，信号量的计数为0
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                flag = granted;
                dispatch_semaphore_signal(semaphore);//信号量的计数＋1
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);//信号量的计数－1，之后如果信号量的计数小于0则进入等待
            break;
        }
        case AVAuthorizationStatusRestricted: {
            flag = false;
            break;
        }
        case AVAuthorizationStatusDenied: {
            flag = false;
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            flag = true;
            break;
        }
    }
    return flag;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
