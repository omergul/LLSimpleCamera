//
//  CameraViewController.m
//  Frizzbee
//
//  Created by Ömer Faruk Gül on 24/10/14.
//  Copyright (c) 2014 Louvre Digital. All rights reserved.
//

#import "LLSimpleCamera.h"
#import <ImageIO/CGImageProperties.h>
#import "UIImage+FixOrientation.h"

@interface LLSimpleCamera ()
@property (nonatomic) CameraQuality cameraQuality;
@property (strong, nonatomic) UIView *preview;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *captureDevice;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@end

@implementation LLSimpleCamera
@synthesize captureDevice = _captureDevice;

- (instancetype)initWithQuality:(CameraQuality)quality {
    self = [super initWithNibName:nil bundle:nil];
    if(self) {
        self.cameraQuality = quality;
        self.fixOrientationAfterCapture = NO;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cameraFlash = CameraFlashOff;
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    self.preview = [[UIView alloc] initWithFrame:CGRectZero];
    self.preview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.preview];
}

// attach camera view to a vc and provide the delegate
- (void)attachToViewController:(UIViewController *)vc withDelegate:(id<LLSimpleCameraDelegate>)delegate {
    self.delegate = delegate;
    [vc.view addSubview:self.view];
    [vc addChildViewController:self];
    [self didMoveToParentViewController:vc];
}

// start viewing the camera
- (void)start {
    
    if(!_session) {
    
        self.session = [[AVCaptureSession alloc] init];
        
        NSString *sessionPreset = nil;
        
        switch (self.cameraQuality) {
            case CameraQualityHigh:
                sessionPreset = AVCaptureSessionPresetHigh;
                break;
            case CameraQualityMedium:
                sessionPreset = AVCaptureSessionPresetMedium;
                break;
            case CameraQualityLow:
                sessionPreset = AVCaptureSessionPresetLow;
                break;
            default:
                sessionPreset = AVCaptureSessionPresetPhoto;
                break;
        }
        
        self.session.sessionPreset = sessionPreset;
        
        CALayer *viewLayer = self.preview.layer;
        
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        
        // set size
        CGRect bounds=viewLayer.bounds;
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        captureVideoPreviewLayer.bounds=bounds;
        captureVideoPreviewLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        [self.preview.layer addSublayer:captureVideoPreviewLayer];
        
        self.captureVideoPreviewLayer = captureVideoPreviewLayer;
        
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];

        if (!input) {
            // Handle the error appropriately.
            NSLog(@"ERROR: trying to open camera: %@", error);
            return;
        }
        [self.session addInput:input];
        
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [self.stillImageOutput setOutputSettings:outputSettings];
        [self.session addOutput:self.stillImageOutput];
    }
    
    [self.session startRunning];
}

// stop session
- (void)stop {
    [self.session stopRunning];
}

- (AVCaptureConnection *)captureConnection {
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    return videoConnection;
}

// capture an image
-(void)capture {
    
    AVCaptureConnection *videoConnection = [self captureConnection];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
         if (exifAttachments) {
             // Do something with the attachments.
             //NSLog(@"attachements: %@", exifAttachments);
         } else {
             //NSLog(@"no attachments");
         }
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         
         if(self.fixOrientationAfterCapture) {
             image = [image fixOrientation];
         }
         
         if(self.delegate) {
             if ([self.delegate respondsToSelector:@selector(cameraViewController:didCaptureImage:)]) {
                 [self.delegate cameraViewController:self didCaptureImage:image];
             }
         }
     }];
}

- (void)setCaptureDevice:(AVCaptureDevice *)captureDevice {
    _captureDevice = captureDevice;
    
    if(self.delegate) {
        if ([self.delegate respondsToSelector:@selector(cameraViewController:didChangeDevice:)]) {
            [self.delegate cameraViewController:self didChangeDevice:captureDevice];
        }
    }
}

- (BOOL)isFlashAvailable {
    AVCaptureInput* currentCameraInput = [self.session.inputs objectAtIndex:0];
    AVCaptureDeviceInput *deviceInput = (AVCaptureDeviceInput *)currentCameraInput;
    
    return deviceInput.device.isTorchAvailable;
}

-(void)setCameraFlash:(CameraFlash)cameraFlash {
    
    AVCaptureInput* currentCameraInput = [self.session.inputs objectAtIndex:0];
    AVCaptureDeviceInput *deviceInput = (AVCaptureDeviceInput *)currentCameraInput;
    
    if(!deviceInput.device.isTorchAvailable) {
        return;
    }
    
    _cameraFlash = cameraFlash;
    
    [self.session beginConfiguration];
    [deviceInput.device lockForConfiguration:nil];
    
    if(_cameraFlash == CameraFlashOn) {
        deviceInput.device.torchMode = AVCaptureTorchModeOn;
    }
    else {
        deviceInput.device.torchMode = AVCaptureTorchModeOff;
    }
    
    [deviceInput.device unlockForConfiguration];
    
    //Commit all the configuration changes at once
    [self.session commitConfiguration];
}

- (CameraPosition)togglePosition {
    if(self.cameraPosition == CameraPositionBack) {
        self.cameraPosition = CameraPositionFront;
    }
    else {
        self.cameraPosition = CameraPositionBack;
    }
    
    return self.cameraPosition;
}

- (CameraFlash)toggleFlash {
    if(self.cameraFlash == CameraFlashOn) {
        self.cameraFlash = CameraFlashOff;
    }
    else {
        self.cameraFlash = CameraFlashOn;
    }
    
    return self.cameraFlash;
}

- (void)setCameraPosition:(CameraPosition)cameraPosition
{
    if(_cameraPosition == cameraPosition) {
        return;
    }
    
    //Indicate that some changes will be made to the session
    [self.session beginConfiguration];
    
    //Remove existing input
    AVCaptureInput* currentCameraInput = [self.session.inputs objectAtIndex:0];
    [self.session removeInput:currentCameraInput];
    
    //Get new input
    AVCaptureDevice *newCamera = nil;
    if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack) {
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
    }
    else {
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }
    
    if(!newCamera) {
        return;
    }
    
    _cameraPosition = cameraPosition;
    
    // add input to session
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:nil];
    [self.session addInput:newVideoInput];
    
    // commit changes
    [self.session commitConfiguration];
    
    self.captureDevice = newCamera;
}


// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) return device;
    }
    return nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
//    NSLog(@"layout cameraVC : %d", self.interfaceOrientation);
    
    self.preview.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    CGRect bounds=self.preview.bounds;
    self.captureVideoPreviewLayer.bounds=bounds;
    self.captureVideoPreviewLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
    
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    self.captureVideoPreviewLayer.connection.videoOrientation = videoOrientation;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
