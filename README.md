# LLSimpleCamera: A simple customizable camera control

![Screenshot](https://raw.githubusercontent.com/omergul123/LLSimpleCamera/master/screenshot.png)

LLSimpleCamera is a library for creating a customized camera screens similar to snapchat's. You don't have to present the camera in a new view controller.

LLSimpleCamera:
* will let you easily capture photos
* handles the position and flash of the camera
* hides the nitty gritty details from the developer

## Example usage

````
CGRect screenRect = [[UIScreen mainScreen] bounds];

// create camera vc
self.camera = [[LLSimpleCamera alloc] initWithQuality:CameraQualityPhoto];

// attach to the view and assign a delegate
[self.camera attachToViewController:self withDelegate:self];

// set the camera view frame to size and origin required for your app
self.camera.view.frame = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height);
````

and here are the example delegates:

````
/* camera delegates */
- (void)cameraViewController:(LLSimpleCamera *)cameraVC didCaptureImage:(UIImage *)image {
    
    // we should stop the camera, since we don't need it anymore. We will open a new vc.
    [self.camera stop];
    
    ImageViewController *imageVC = [[ImageViewController alloc] initWithImage:image];
    [self presentViewController:imageVC animated:NO completion:nil];
}

- (void)cameraViewController:(LLSimpleCamera *)cameraVC didChangeDevice:(AVCaptureDevice *)device {
    
    // device changed, check if flash is available
    if(cameraVC.isFlashAvailable) {
        self.flashButton.hidden = NO;
    }
    else {
        self.flashButton.hidden = YES;
    }
    
    self.flashButton.selected = NO;
}
````

## Adding the camera controls

You have to add your own camera controls (flash, camera switch etc). Simply add the controls to the view that the camera is attached to. You can see a full camera example in the example project. Download and try it on your device.

## Contact

Ömer Faruk Gül

[My LinkedIn Account][2]

 [2]: http://www.linkedin.com/profile/view?id=44437676


