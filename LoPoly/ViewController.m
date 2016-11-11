// ViewController.m
// This contains the private interface and implementation of the ViewController class.

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <opencv2/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>

#pragma clang diagnostic pop

#ifdef WITH_OPENCV_CONTRIB
#import <opencv/xphoto.hpp>
#endif

#import "ViewController.h"

// The arc4random() function returns a random 32-bit integer in the range of 0 to 2^32-1 (or 0x100000000). The  first time it is called, the function automatically seeds the random number generator.
#define RAND_0_1() ((double)arc4random() / 0x100000000)

@interface ViewController () {
  cv::Mat originalMat;
  cv::Mat updatedMat;
}

@property IBOutlet UIImageView *imageView;
@property NSTimer *timer;

- (void) updateImage;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  
  // Load a UIImage from a resource file.
  UIImage *originalImage = [UIImage imageNamed:@"Fiddle.png"];
  
  // Convert the UIImage to a cv::Mat.
  UIImageToMat(originalImage, originalMat);
  
  switch(originalMat.type()) {
    case CV_8UC1:
      // The cv::Mat is in grayscale format.
      // Convert to RGB.
      cv::cvtColor(originalMat, originalMat, cv::COLOR_GRAY2RGB);
      break;
      
    case CV_8UC4:
      // The cv::Mat is in RGBA format.
      // Convert to RGB.
      cv::cvtColor(originalMat, originalMat, cv::COLOR_RGBA2RGB);
      
      // Adjust white balance.
      #ifdef WITH_OPENCV_CONTRIB
      cv::xphoto::WhiteBalancer *wb;
      wb->balanceWhite(originalMat, originalMat);
      #endif
      break;
      
    case CV_8UC3:
      // The cv::Mat is in RGB format.
      #ifdef WITH_OPENCV_CONTRIB
      wb->balanceWhite(originalMat, originalMat);
      #endif
      break;
      
    default:
      break;
  }
  
  // Call an update method every 2 seconds.
  // NSTimer only  res callbacks when the app is in the foreground. This behavior is convenient for our purposes because we only want to update the image when it is visible.
  self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
}

- (void) updateImage {
  // Generate a random color.
  double r = 0.5 + RAND_0_1() * 1.0;
  double g = 0.6 + RAND_0_1() * 0.8;
  double b = 0.4 + RAND_0_1() * 1.2;
  cv::Scalar randomColor(r, g, b);
  
  // Create an updated, tinted cv::Mat by multiplying the original matrix and the random color.
  cv::multiply(originalMat, randomColor, updatedMat);
  
  // Convert the updated matrix to a UIImage and display it in the UIImageView.
  self.imageView.image = MatToUIImage(updatedMat);
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


@end
