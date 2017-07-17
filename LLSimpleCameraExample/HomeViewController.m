//
//  HomeViewController.m
//  LLSimpleCameraExample
//
//  Created by Ömer Faruk Gül on 29/10/14.
//  Copyright (c) 2014 Ömer Faruk Gül. All rights reserved.
//

#import "HomeViewController.h"
#import "ViewUtils.h"
#import "ImageViewController.h"
#import "VideoViewController.h"

@interface HomeViewController ()
@property (strong, nonatomic) LLSimpleCamera *camera;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UIButton *snapButton;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;

@property (strong, nonatomic) UIButton *lockFocusButton;
@property (strong, nonatomic) UIButton *lockExposureButton;
@property (strong, nonatomic) UISlider *frameRateSlider;
@property (strong, nonatomic) UILabel *frameRateLabel;
@property (strong, nonatomic) UIProgressView *soundLevelProgress;
@property (strong, nonatomic) UILabel *soundLevelProgressLabel;

@end

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    // ----- initialize camera -------- //
    
    // create camera vc
    self.camera = [[LLSimpleCamera alloc] initWithQuality:AVCaptureSessionPresetHigh
                                                 position:LLCameraPositionRear
                                             videoEnabled:YES];
    
    // attach to a view controller
    [self.camera attachToViewController:self withFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    
    // read: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
    // you probably will want to set this to YES, if you are going view the image outside iOS.
    self.camera.fixOrientationAfterCapture = NO;
    
    // take the required actions on a device change
    __weak typeof(self) weakSelf = self;
    [self.camera setOnDeviceChange:^(LLSimpleCamera *camera, AVCaptureDevice * device) {
        
        NSLog(@"Device changed.");
        
        // device changed, check if flash is available
        if([camera isFlashAvailable]) {
            weakSelf.flashButton.hidden = NO;
            
            if(camera.flash == LLCameraFlashOff) {
                weakSelf.flashButton.selected = NO;
            }
            else {
                weakSelf.flashButton.selected = YES;
            }
        }
        else {
            weakSelf.flashButton.hidden = YES;
        }
        
        if(weakSelf.frameRateSlider) {
            weakSelf.frameRateSlider.value = weakSelf.camera.maxFrameRate;
            weakSelf.frameRateLabel.text = [NSString stringWithFormat:@"Frame Rate \nMin:%.2f, Max:%.2f\nValue:%.2f",weakSelf.camera.minFrameRate,weakSelf.camera.maxFrameRate,weakSelf.camera.maxFrameRate];
        }
        
        [weakSelf updateLockFocusButtonTitle];
        [weakSelf updateLockExposureButtonTitle];
        
    }];
    
    [self.camera setOnError:^(LLSimpleCamera *camera, NSError *error) {
        NSLog(@"Camera error: %@", error);
        
        if([error.domain isEqualToString:LLSimpleCameraErrorDomain]) {
            if(error.code == LLSimpleCameraErrorCodeCameraPermission ||
               error.code == LLSimpleCameraErrorCodeMicrophonePermission) {
                
                if(weakSelf.errorLabel) {
                    [weakSelf.errorLabel removeFromSuperview];
                }
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.text = @"We need permission for the camera.\nPlease go to your settings.";
                label.numberOfLines = 2;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13.0f];
                label.textColor = [UIColor whiteColor];
                label.textAlignment = NSTextAlignmentCenter;
                [label sizeToFit];
                label.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                weakSelf.errorLabel = label;
                [weakSelf.view addSubview:weakSelf.errorLabel];
            }
        }
    }];
    
    // ----- camera buttons -------- //
    
    // snap button to capture image
    self.snapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.snapButton.frame = CGRectMake(0, 0, 70.0f, 70.0f);
    self.snapButton.clipsToBounds = YES;
    self.snapButton.layer.cornerRadius = self.snapButton.width / 2.0f;
    self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.snapButton.layer.borderWidth = 2.0f;
    self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.snapButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.snapButton.layer.shouldRasterize = YES;
    [self.snapButton addTarget:self action:@selector(snapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.snapButton];
    
    // button to toggle flash
    self.flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.flashButton.frame = CGRectMake(0, 0, 16.0f + 20.0f, 24.0f + 20.0f);
    self.flashButton.tintColor = [UIColor whiteColor];
    [self.flashButton setImage:[UIImage imageNamed:@"camera-flash.png"] forState:UIControlStateNormal];
    self.flashButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    if([LLSimpleCamera isFrontCameraAvailable] && [LLSimpleCamera isRearCameraAvailable]) {
        // button to toggle camera positions
        self.switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.switchButton.frame = CGRectMake(0, 0, 29.0f + 20.0f, 22.0f + 20.0f);
        self.switchButton.tintColor = [UIColor whiteColor];
        [self.switchButton setImage:[UIImage imageNamed:@"camera-switch.png"] forState:UIControlStateNormal];
        self.switchButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
        [self.switchButton addTarget:self action:@selector(switchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.switchButton];
    }
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Picture",@"Video"]];
    self.segmentedControl.frame = CGRectMake(12.0f, screenRect.size.height - 67.0f, 120.0f, 32.0f);
    self.segmentedControl.selectedSegmentIndex = 0;
    self.segmentedControl.tintColor = [UIColor whiteColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];
    
    // Button for focus lock
    self.lockFocusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.lockFocusButton.frame = CGRectMake(10.0, 10.0, 100.0, 50.0);
    self.lockFocusButton.backgroundColor = [UIColor clearColor];
    self.lockFocusButton.layer.borderWidth = 1.0;
    self.lockFocusButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.lockFocusButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.lockFocusButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [self.lockFocusButton addTarget:self action:@selector(lockFocusButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self updateLockFocusButtonTitle];
    [self.view addSubview:self.lockFocusButton];
    
    // Button for exposure lock
    self.lockExposureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.lockExposureButton.frame = CGRectMake(10.0, 70.0, 120.0, 50.0);
    self.lockExposureButton.backgroundColor = [UIColor clearColor];
    self.lockExposureButton.layer.borderWidth = 1.0;
    self.lockExposureButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.lockExposureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.lockExposureButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [self.lockExposureButton addTarget:self action:@selector(lockExposureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self updateLockExposureButtonTitle];
    [self.view addSubview:self.lockExposureButton];
    
    self.frameRateLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 160.0, 130.0, 80.0)];
    self.frameRateLabel.text = @"";
    self.frameRateLabel.font = [UIFont systemFontOfSize:12.0];
    self.frameRateLabel.numberOfLines = 0;
    self.frameRateLabel.adjustsFontSizeToFitWidth = YES;
    self.frameRateLabel.minimumScaleFactor = 10.0f/12.0f;
    self.frameRateLabel.backgroundColor = [UIColor clearColor];
    self.frameRateLabel.textColor = [UIColor whiteColor];
    self.frameRateLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.frameRateLabel];
    
    self.frameRateSlider = [[UISlider alloc] initWithFrame:CGRectMake(10.0, 130.0, 120.0, 50.0)];
    [self.frameRateSlider addTarget:self action:@selector(frameRateSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.frameRateSlider setBackgroundColor:[UIColor clearColor]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Warning: Delaying 2 sec for camera to fully initialize,
        // after start function is called from viewWillAppear
        // You can call it from there after the camera initialization
        self.frameRateSlider.minimumValue = self.camera.minFrameRate;
        self.frameRateSlider.maximumValue = self.camera.maxFrameRate;
        self.frameRateSlider.continuous = NO;
        self.frameRateSlider.value = self.camera.maxFrameRate;
        
        self.frameRateLabel.text = [NSString stringWithFormat:@"Frame Rate \nMin:%.2f, Max:%.2f\nValue:%.2f",self.camera.minFrameRate,self.camera.maxFrameRate,self.camera.maxFrameRate];
        
        [self.view addSubview:self.frameRateSlider];
    });
    
    self.soundLevelProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.soundLevelProgress.progressTintColor = [UIColor colorWithRed:187.0/255 green:160.0/255 blue:209.0/255 alpha:1.0];
    [[self.soundLevelProgress layer]setFrame:CGRectMake(10.0, 250.0, 120, 20)];
    [[self.soundLevelProgress layer]setBorderColor:[UIColor whiteColor].CGColor];
    self.soundLevelProgress.trackTintColor = [UIColor clearColor];
    [self.soundLevelProgress setProgress:0.0 animated:YES];
    self.soundLevelProgress.progress=0.0;
    [[self.soundLevelProgress layer]setCornerRadius:4.0];
    [[self.soundLevelProgress layer]setBorderWidth:1];
    [[self.soundLevelProgress layer]setMasksToBounds:TRUE];
    self.soundLevelProgress.clipsToBounds = YES;
    
    [self.view addSubview:self.soundLevelProgress];
    
    [NSTimer scheduledTimerWithTimeInterval:1/30 repeats:YES block:^(NSTimer * _Nonnull timer) {
        self.soundLevelProgress.progress = [self.camera getChannelSoundPowerLevel];
    }];
    self.soundLevelProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 280.0, 130.0, 30.0)];
    self.soundLevelProgressLabel.text = @"Sound Power Level";
    self.soundLevelProgressLabel.font = [UIFont systemFontOfSize:12.0];
    self.soundLevelProgressLabel.numberOfLines = 0;
    self.soundLevelProgressLabel.adjustsFontSizeToFitWidth = YES;
    self.soundLevelProgressLabel.minimumScaleFactor = 10.0f/12.0f;
    self.soundLevelProgressLabel.backgroundColor = [UIColor clearColor];
    self.soundLevelProgressLabel.textColor = [UIColor whiteColor];
    self.soundLevelProgressLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.soundLevelProgressLabel];
}

- (void)frameRateSliderValueChanged:(id)sender {
    UISlider *slider = (UISlider*)sender;
    [self.camera changeFrameRate:slider.value];
    self.frameRateLabel.text = [NSString stringWithFormat:@"Frame Rate \nMin:%.2f, Max:%.2f\nValue:%.2f",self.camera.minFrameRate,self.camera.maxFrameRate,slider.value];
}

- (IBAction)lockFocusButtonPressed:(id)sender {
    if(!self.camera.isFocusLockedByUser)
        [self.camera lockFocus:YES];
    else
        [self.camera lockFocus:NO];
    [self updateLockFocusButtonTitle];
}

- (void)updateLockFocusButtonTitle {
    if(self.camera.isFocusLockedByUser)
        [self.lockFocusButton setTitle:@"Focus Lock: On" forState:UIControlStateNormal];
    else
        [self.lockFocusButton setTitle:@"Focus Lock: Off" forState:UIControlStateNormal];
    
}

- (IBAction)lockExposureButtonPressed:(id)sender {
    if(!self.camera.isExpouserLockedByUser)
        [self.camera lockExposure:YES];
    else
        [self.camera lockExposure:NO];
    [self updateLockExposureButtonTitle];
}

- (void)updateLockExposureButtonTitle {
    if(self.camera.isExpouserLockedByUser)
        [self.lockExposureButton setTitle:@"Exposure Lock: On" forState:UIControlStateNormal];
    else
        [self.lockExposureButton setTitle:@"Exposure Lock: Off" forState:UIControlStateNormal];
    
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)control
{
    NSLog(@"Segment value changed!");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // start the camera
    [self.camera start];
}

/* camera button methods */

- (void)switchButtonPressed:(UIButton *)button
{
    [self.camera togglePosition];
}

- (void)callSOundLevel {
    NSLog(@"%f",[self.camera getChannelSoundPowerLevel]);
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)flashButtonPressed:(UIButton *)button
{
    if(self.camera.flash == LLCameraFlashOff) {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOn];
        if(done) {
            self.flashButton.selected = YES;
            self.flashButton.tintColor = [UIColor yellowColor];
        }
    }
    else {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOff];
        if(done) {
            self.flashButton.selected = NO;
            self.flashButton.tintColor = [UIColor whiteColor];
        }
    }
}

- (void)snapButtonPressed:(UIButton *)button
{
    __weak typeof(self) weakSelf = self;
    
    if(self.segmentedControl.selectedSegmentIndex == 0) {
        // capture
        [self.camera capture:^(LLSimpleCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error) {
            if(!error) {
                ImageViewController *imageVC = [[ImageViewController alloc] initWithImage:image];
                [weakSelf presentViewController:imageVC animated:NO completion:nil];
            }
            else {
                NSLog(@"An error has occured: %@", error);
            }
        } exactSeenImage:YES];
        
    } else {
        if(!self.camera.isRecording) {
            self.segmentedControl.hidden = YES;
            self.flashButton.hidden = YES;
            self.switchButton.hidden = YES;
            
            self.snapButton.layer.borderColor = [UIColor redColor].CGColor;
            self.snapButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
            
            // start recording
            NSURL *outputURL = [[[self applicationDocumentsDirectory]
                                 URLByAppendingPathComponent:@"test1"] URLByAppendingPathExtension:@"mov"];
            [self.camera startRecordingWithOutputUrl:outputURL didRecord:^(LLSimpleCamera *camera, NSURL *outputFileUrl, NSError *error) {
                VideoViewController *vc = [[VideoViewController alloc] initWithVideoUrl:outputFileUrl];
                [self.navigationController pushViewController:vc animated:YES];
            }];
            
        } else {
            self.segmentedControl.hidden = NO;
            self.flashButton.hidden = NO;
            self.switchButton.hidden = NO;
            
            self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
            self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
            
            [self.camera stopRecording];
        }
    }
}

/* other lifecycle methods */

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.camera.view.frame = self.view.contentBounds;
    
    self.snapButton.center = self.view.contentCenter;
    self.snapButton.bottom = self.view.height - 15.0f;
    
    self.flashButton.center = self.view.contentCenter;
    self.flashButton.top = 5.0f;
    
    self.switchButton.top = 5.0f;
    self.switchButton.right = self.view.width - 5.0f;
    
    self.segmentedControl.left = 12.0f;
    self.segmentedControl.bottom = self.view.height - 35.0f;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
