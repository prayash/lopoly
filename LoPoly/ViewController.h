// ViewController.h
// Prayash Thapa

// This defines the public interface of a ViewController class. This class is
// responsible for managing the application's main scene, which we saw in Main.Storyboard.

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>

#import "VideoCamera.h"

#import "LGSideMenuController.h"
#import "UIViewController+LGSideMenuController.h"

@interface ViewController : UIViewController <CvVideoCameraDelegate>

// Main image view which displays the output image
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

// Intervalometer to keep updateImage going
@property NSTimer *timer;

// Updates image colors and such.
- (void) updateImage;

@property IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property IBOutlet UIToolbar *toolbar;
@property VideoCamera *videoCamera;
@property BOOL saveNextFrame;

- (IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)tapGesture;
- (IBAction)onSwitchCameraButtonPressed;
- (IBAction)onSaveButtonPressed;

- (void)refresh;
- (void)processImage:(cv::Mat &)mat;
- (void)processImageHelper:(cv::Mat &)mat;
- (void)saveImage:(UIImage *)image;
- (void)showSaveImageFailureAlertWithMessage:(NSString *)message;
- (void)showSaveImageSuccessAlertWithImage:(UIImage *)image;
- (UIAlertAction *)shareImageActionWithTitle:(NSString *)title
                                 serviceType:(NSString *)serviceType image:(UIImage *)image;
- (void)startBusyMode;
- (void)stopBusyMode;

- (void)setLeftViewEnabledWithWidth:(CGFloat)width presentationStyle:(LGSideMenuPresentationStyle)presentationStyle alwaysVisibleOptions:(LGSideMenuAlwaysVisibleOptions)alwaysVisibleOptions;

@end

