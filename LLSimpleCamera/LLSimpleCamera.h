//
//  CameraViewController.h
//  Frizzbee
//
//  Created by Ömer Faruk Gül on 24/10/14.
//  Copyright (c) 2014 Louvre Digital. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum : NSUInteger {
    CameraPositionBack,
    CameraPositionFront
} CameraPosition;

typedef enum : NSUInteger {
    // The default state has to be off
    // FIXES: Unresposive first touch to toggle flash.
    CameraFlashOff,
    CameraFlashOn
} CameraFlash;

typedef enum : NSUInteger {
    CameraQualityLow,
    CameraQualityMedium,
    CameraQualityHigh,
    CameraQualityPhoto
} CameraQuality;

@protocol LLSimpleCameraDelegate;

@interface LLSimpleCamera : UIViewController

/**
The LLSimpleCameraDelegate delegate.
 */
@property (nonatomic, weak) id<LLSimpleCameraDelegate> delegate;

/**
 The status of the camera flash.
 */
@property (nonatomic) CameraFlash cameraFlash;
/**
 The position of the camera.
 */
@property (nonatomic) CameraPosition cameraPosition;

/**
 Fixess the orientation after the image is captured is set to Yes.
 see: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
 */
@property (nonatomic) BOOL fixOrientationAfterCapture;

/**
 Returns an instance of LLSimpleCamera with the given quality.
 @param quality The quality of the camera.
 */
- (instancetype)initWithQuality:(CameraQuality)quality;

/**
 Starts running the camera session.
 */
- (void)start;

/**
 Stops the running camera session. Needs to be called when the app doesn't show the view.
 */
- (void)stop;

/**
 Attaches the LLSimpleCamera to another vs with a delegate. It basically adds the LLSimpleCamera as a
 child vc to the given vc.
 @param vc A view controller.
 @param delegate The LLSimpleCamera delegate vc.
 */
- (void)attachToViewController:(UIViewController *)vc withDelegate:(id<LLSimpleCameraDelegate>)delegate;

/**
 Changes the posiition of the camera (either back or front) and returns the final position.
 */
- (CameraPosition)togglePosition;

/**
 Toggles the flash. If the device doesn't have a flash it returns CameraFlashOff.
 */
- (CameraFlash)toggleFlash;

/**
 Checks if flash is avilable for the currently active device.
 */
- (BOOL)isFlashAvailable;

/**
 Capture the image.
 */
- (void)capture;
@end

@protocol LLSimpleCameraDelegate <NSObject>
/**
 Triggered when the active camera device is changed. Programmer can use isFlashAvailable to check if the flash
 is available and show the related icons.
 */
- (void)cameraViewController:(LLSimpleCamera*)cameraVC
             didChangeDevice:(AVCaptureDevice *)device;

/**
 Triggered after the image is captured by the camera.
 */
- (void)cameraViewController:(LLSimpleCamera*)cameraVC
             didCaptureImage:(UIImage *)image;
@end
