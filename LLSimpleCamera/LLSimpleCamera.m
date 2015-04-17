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
@property (strong, nonatomic) UIView *preview;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *captureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *deviceInput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) CALayer *focusBoxLayer;
@property (strong, nonatomic) CAAnimation *focusBoxAnimation;
@end

NSString *const LLSimpleCameraErrorDomain = @"LLSimpleCameraErrorDomain";

@implementation LLSimpleCamera

- (instancetype)initWithQuality:(CameraQuality)quality andPosition:(CameraPosition)position {
    self = [super initWithNibName:nil bundle:nil];
    if(self) {
        self.cameraQuality = quality;
        self.cameraPosition = position;
        self.fixOrientationAfterCapture = NO;
        self.tapToFocus = YES;
        self.useDeviceOrientation = NO;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _flash = CameraFlashOff;
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingNone;
    
    self.preview = [[UIView alloc] initWithFrame:CGRectZero];
    self.preview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.preview];
    
    // tap to focus
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewTapped:)];
    self.tapGesture.numberOfTapsRequired = 1;
    [self.tapGesture setDelaysTouchesEnded:NO];
    [self.preview addGestureRecognizer:self.tapGesture];
    
    // add focus box to view
    [self addDefaultFocusBox];
}

- (void)addDefaultFocusBox {
    
    CALayer *focusBox = [[CALayer alloc] init];
    focusBox.cornerRadius = 5.0f;
    focusBox.bounds = CGRectMake(0.0f, 0.0f, 70, 60);
    focusBox.borderWidth = 3.0f;
    focusBox.borderColor = [[UIColor yellowColor] CGColor];
    focusBox.opacity = 0.0f;
    [self.view.layer addSublayer:focusBox];
    
    CABasicAnimation *focusBoxAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    focusBoxAnimation.duration = 0.75;
    focusBoxAnimation.autoreverses = NO;
    focusBoxAnimation.repeatCount = 0.0;
    focusBoxAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    focusBoxAnimation.toValue = [NSNumber numberWithFloat:0.0];
    
    [self alterFocusBox:focusBox animation:focusBoxAnimation];
}

- (void)alterFocusBox:(CALayer *)layer animation:(CAAnimation *)animation {
    self.focusBoxLayer = layer;
    self.focusBoxAnimation = animation;
}

- (void)attachToViewController:(UIViewController *)vc withFrame:(CGRect)frame {
    [vc.view addSubview:self.view];
    [vc addChildViewController:self];
    [self didMoveToParentViewController:vc];
    
    vc.view.frame = frame;
}

# pragma mark Touch Delegate

- (void) previewTapped: (UIGestureRecognizer *) gestureRecognizer
{
    if(!self.tapToFocus) {
        return;
    }
    
    CGPoint touchedPoint = (CGPoint) [gestureRecognizer locationInView:self.preview];
    
    // focus
    CGPoint pointOfInterest = [self convertToPointOfInterestFromViewCoordinates:touchedPoint];
    [self focusAtPoint:pointOfInterest];
    
    // show the box
    [self showFocusBox:touchedPoint];
}

#pragma mark Camera Actions

- (void)start {
    // in iOS7 & iOS8 we have check if we have permission t camera
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initialize];
                });
            } else {
                NSError *error = [NSError errorWithDomain:LLSimpleCameraErrorDomain
                                                 code:LLSimpleCameraErrorCodePermission
                                             userInfo:nil];
                
                if(self.onError) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.onError(self, error);
                    });
                }
            }
        }];
    } else {
        [self initialize];
    }
}

- (void)initialize {
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
        
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        
        // set size
        CGRect bounds = self.preview.layer.bounds;
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        captureVideoPreviewLayer.bounds = bounds;
        captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        [self.preview.layer addSublayer:captureVideoPreviewLayer];
        
        self.captureVideoPreviewLayer = captureVideoPreviewLayer;
        
        AVCaptureDevicePosition devicePosition;
        switch (self.position) {
            case CameraPositionBack:
                devicePosition = AVCaptureDevicePositionBack;
                break;
            case CameraPositionFront:
                devicePosition = AVCaptureDevicePositionFront;
                break;
            default:
                devicePosition = AVCaptureDevicePositionUnspecified;
                break;
        }
        
        if(devicePosition == AVCaptureDevicePositionUnspecified) {
            self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        }
        else {
            self.captureDevice = [self cameraWithPosition:devicePosition];
        }
        
        NSError *error = nil;
        _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
        
        if (!_deviceInput) {
            if(self.onError) {
                self.onError(self, error);
            }
            return;
        }
        [self.session addInput:_deviceInput];
        
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [self.stillImageOutput setOutputSettings:outputSettings];
        [self.session addOutput:self.stillImageOutput];
    }
    
    //if we had disabled the connection on capture, re-enable it
    if (![self.captureVideoPreviewLayer.connection isEnabled]) {
        [self.captureVideoPreviewLayer.connection setEnabled:YES];
    }
    
    [self.session startRunning];
}

- (void)stop {
    [self.session stopRunning];
}


-(void)capture:(void (^)(LLSimpleCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture exactSeenImage:(BOOL)exactSeenImage {
    
    if(!self.session) {
        NSError *error = [NSError errorWithDomain:LLSimpleCameraErrorDomain
                                    code:LLSimpleCameraErrorCodeSession
                                userInfo:nil];
        onCapture(self, nil, nil, error);
        return;
    }
    
    // get connection and set orientation
    AVCaptureConnection *videoConnection = [self captureConnection];
    videoConnection.videoOrientation = [self orientationForConnection];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
         //Stop capturing data to freeze the screen to indicate the pictrue has been taken
         [self.captureVideoPreviewLayer.connection setEnabled:NO];
         
         UIImage *image = nil;
         NSDictionary *metadata = nil;
         
         // check if we got the image buffer
         if (imageSampleBuffer != NULL) {
             CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
             if(exifAttachments) {
                 metadata = (__bridge NSDictionary*)exifAttachments;
             }
             
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             image = [[UIImage alloc] initWithData:imageData];
             
             if(exactSeenImage) {
                 image = [self cropImageUsingPreviewBounds:image];
             }
             
             if(self.fixOrientationAfterCapture) {
                 image = [image fixOrientation];
             }
         }
         
         // trigger the block
         if(onCapture) {
             onCapture(self, image, metadata, error);
         }
     }];
}

-(void)capture:(void (^)(LLSimpleCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture {
    [self capture:onCapture exactSeenImage:NO];
}


- (UIImage *)cropImageUsingPreviewBounds:(UIImage *)image {
    CGRect outputRect = [self.captureVideoPreviewLayer metadataOutputRectOfInterestForRect:self.captureVideoPreviewLayer.bounds];
    CGImageRef takenCGImage = image.CGImage;
    size_t width = CGImageGetWidth(takenCGImage);
    size_t height = CGImageGetHeight(takenCGImage);
    CGRect cropRect = CGRectMake(outputRect.origin.x * width, outputRect.origin.y * height, outputRect.size.width * width, outputRect.size.height * height);
    
    CGImageRef cropCGImage = CGImageCreateWithImageInRect(takenCGImage, cropRect);
    image = [UIImage imageWithCGImage:cropCGImage scale:1 orientation:image.imageOrientation];
    CGImageRelease(cropCGImage);
    
    return image;
}

#pragma mark Helper Methods

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

- (void)setCaptureDevice:(AVCaptureDevice *)captureDevice {
    _captureDevice = captureDevice;
    
    if(captureDevice.flashMode == AVCaptureFlashModeAuto) {
        _flash = CameraFlashAuto;
    }
    else if(captureDevice.flashMode == AVCaptureFlashModeOn) {
        _flash = CameraFlashOn;
    }
    else if(captureDevice.flashMode == AVCaptureFlashModeOff) {
        _flash = CameraFlashOff;
    }
    else {
        _flash = CameraFlashOff;
    }
    
    // trigger block
    if(self.onDeviceChange) {
        self.onDeviceChange(self, captureDevice);
    }
}

- (BOOL)isFlashAvailable {
    return self.captureDevice.isFlashAvailable;
}

- (BOOL)updateFlashMode:(CameraFlash)cameraFlash {
    if(!self.session)
        return NO;
    
    AVCaptureFlashMode flashMode;
    
    if(cameraFlash == CameraFlashOn) {
        flashMode = AVCaptureFlashModeOn;
    }
    else if(cameraFlash == CameraFlashAuto) {
        flashMode = AVCaptureFlashModeAuto;
    }
    else {
        flashMode = AVCaptureFlashModeOff;
    }
    
    
    if([_captureDevice isFlashModeSupported:flashMode]) {
        NSError *error;
        if([_captureDevice lockForConfiguration:&error]) {
            _captureDevice.flashMode = flashMode;
            [_captureDevice unlockForConfiguration];
            
            _flash = cameraFlash;
            return YES;
        }
        else {
            if(self.onError) {
                self.onError(self, error);
            }
            return NO;
        }
    }
    else {
        return NO;
    }
}

- (CameraPosition)togglePosition {
    if(!self.session) {
        return self.position;
    }
    
    if(self.position == CameraPositionBack) {
        self.cameraPosition = CameraPositionFront;
    }
    else {
        self.cameraPosition = CameraPositionBack;
    }
    
    return self.position;
}

- (void)setCameraPosition:(CameraPosition)cameraPosition
{
    if(_position == cameraPosition || !self.session) {
        return;
    }
    
    // indicate that some changes will be made to the session
    [self.session beginConfiguration];
    
    // remove existing input
    AVCaptureInput* currentCameraInput = [self.session.inputs objectAtIndex:0];
    [self.session removeInput:currentCameraInput];
    
    // get new input
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
    
    // add input to session
    NSError *error = nil;
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&error];
    if(error) {
        if(self.onError) {
            self.onError(self, error);
        }
        [self.session commitConfiguration];
        return;
    }
    
    _position = cameraPosition;
    
    [self.session addInput:newVideoInput];
    [self.session commitConfiguration];
    
    self.captureDevice = newCamera;
}


// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) return device;
    }
    return nil;
}

#pragma mark Focus

- (void) focusAtPoint:(CGPoint)point
{
    //NSLog(@"Focusing at point %@", NSStringFromCGPoint(point));
    
    AVCaptureDevice *device = _deviceInput.device;
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        }
        
        if(error && self.onError) {
            self.onError(self, error);
        }
    }
}

- (void)showFocusBox:(CGPoint)point {
    
    if(self.focusBoxLayer) {
        // clear animations
        [self.focusBoxLayer removeAllAnimations];
        
        // move layer to the touc point
        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
        self.focusBoxLayer.position = point;
        [CATransaction commit];
    }
    
    if(self.focusBoxAnimation) {
        // run the animation
        [self.focusBoxLayer addAnimation:self.focusBoxAnimation forKey:@"animateOpacity"];
    }
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    AVCaptureVideoPreviewLayer *previewLayer = self.captureVideoPreviewLayer;
    
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = previewLayer.frame.size;
    
    if ( [previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize] ) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [self.session.inputs.lastObject ports]) {
            if (port.mediaType == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}


#pragma mark - Controller Lifecycle

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
    
    CGRect bounds = self.preview.bounds;
    self.captureVideoPreviewLayer.bounds = bounds;
    self.captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    self.captureVideoPreviewLayer.connection.videoOrientation = [self orientationForConnection];
}

- (AVCaptureVideoOrientation)orientationForConnection
{
    AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
    
    if(self.useDeviceOrientation) {
        switch ([UIDevice currentDevice].orientation) {
            case UIDeviceOrientationLandscapeLeft:
                // yes we to the right, this is not bug!
                videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIDeviceOrientationLandscapeRight:
                videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            default:
                videoOrientation = AVCaptureVideoOrientationPortrait;
                break;
        }
    }
    else {
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
    }
    
    return videoOrientation;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end