# LLSimpleCamera: A simple customizable camera control

![Screenshot](https://raw.githubusercontent.com/omergul123/LLSimpleCamera/master/screenshot.png)

LLSimpleCamera is a library for creating a customized camera screens similar to snapchat's. You don't have to present the camera in a new view controller.

**LLSimpleCamera:**
* lets you easily capture photos
* handles the position and flash of the camera
* hides the nitty gritty details from the developer
* doesn't have to be presented in a new modal view controller, simply can be embedded inside any of your VCs. (like Snapchat)

### Version 1.1.1
- fixed a potential crash scenario if -stop() is called multiple times

### Version 1.1.0
- fixed a problem that sometimes caused a crash after capturing a photo.
- improved code structure, didChangeDevice delegate is now also triggered for the first default device.

## Install

pod 'LLSimpleCamera', '~> 1.1'

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

You have to add your own camera controls (flash, camera switch etc). Simply add the controls to the view where LLSimpleCamera is attached to. You can see a full camera example in the example project. Download and try it on your device.

## Stopping and restarting the camera

You should never forget to stop the camera either after the **didCaptureImage** delegate is triggered, or inside somewhere **-viewWillDisappear** of the parent controller to make sure that the app doesn't use the camera when it is not needed. You can call **-start()** to use the camera. So it may be good idea to to place **-start()** inside **-viewWillAppear** or in another relevant method.

## Contact

Ömer Faruk Gül

[My LinkedIn Account][2]

 [2]: http://www.linkedin.com/profile/view?id=44437676


