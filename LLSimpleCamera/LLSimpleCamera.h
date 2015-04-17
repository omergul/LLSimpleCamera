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
    CameraFlashOff,
    CameraFlashOn,
    CameraFlashAuto
} CameraFlash;

typedef enum : NSUInteger {
    CameraQualityLow,
    CameraQualityMedium,
    CameraQualityHigh,
    CameraQualityPhoto
} CameraQuality;

extern NSString *const LLSimpleCameraErrorDomain;
typedef enum : NSUInteger {
    LLSimpleCameraErrorCodePermission = 10,
    LLSimpleCameraErrorCodeSession = 11
} LLSimpleCameraErrorCode;

@interface LLSimpleCamera : UIViewController

/**
 * Triggered on device change.
 */
@property (nonatomic, copy) void (^onDeviceChange)(LLSimpleCamera *camera, AVCaptureDevice *device);

/**
 * Triggered on any kind of error.
 */
@property (nonatomic, copy) void (^onError)(LLSimpleCamera *camera, NSError *error);

/**
 * Camera quality, changing the value will only take effect at [LLSimpleCamera start]
 */
@property (nonatomic) CameraQuality cameraQuality;

/**
 * Camera flash mode.
 */
@property (nonatomic, readonly) CameraFlash flash;

/**
 * Position of the camera.
 */
@property (nonatomic) CameraPosition position;

/**
 * Fixess the orientation after the image is captured is set to Yes.
 * see: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
 */
@property (nonatomic) BOOL fixOrientationAfterCapture;

/**
 * Set NO if you don't want ot enable user triggered focusing. Enabled by default.
 */
@property (nonatomic) BOOL tapToFocus;

/**
 * Set YES if you your view controller does not allow autorotation,
 * however you want to take the device rotation into account no matter what. Disabled by default.
 */
@property (nonatomic) BOOL useDeviceOrientation;

/**
 * Returns an instance of LLSimpleCamera with the given quality.
 * @param quality The quality of the camera.
 */
- (instancetype)initWithQuality:(CameraQuality)quality andPosition:(CameraPosition)position;

/**
 * Starts running the camera session.
 */
- (void)start;

/**
 * Stops the running camera session. Needs to be called when the app doesn't show the view.
 */
- (void)stop;

/**
 * Attaches the LLSimpleCamera to another view controller with a frame. It basically adds the LLSimpleCamera as a
 * child vc to the given vc.
 * @param vc A view controller.
 * @param frame The frame of the camera.
 */
- (void)attachToViewController:(UIViewController *)vc withFrame:(CGRect)frame;

/**
 * Changes the posiition of the camera (either back or front) and returns the final position.
 */
- (CameraPosition)togglePosition;

/**
 * Update the flash mode of the camera. Returns true if it is successful. Otherwise false.
 */
- (BOOL)updateFlashMode:(CameraFlash)cameraFlash;

/**
 * Checks if flash is avilable for the currently active device.
 */
- (BOOL)isFlashAvailable;

/**
 * Alter the layer and the animation displayed when the user taps on screen.
 * @param layer Layer to be displayed
 * @param animation to be applied after the layer is shown
 */
- (void)alterFocusBox:(CALayer *)layer animation:(CAAnimation *)animation;


/**
 * Capture the image.
 * @param onCapture a block triggered after the capturing the photo.
 * @param exactSeenImage If set YES, then the image is cropped to the exact size as the preview. So you get exactly what you see.
 */
-(void)capture:(void (^)(LLSimpleCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture exactSeenImage:(BOOL)exactSeenImage;

/**
 * Capture the image.
 * @param onCapture a block triggered after the capturing the photo.
 */
-(void)capture:(void (^)(LLSimpleCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture;


@end
