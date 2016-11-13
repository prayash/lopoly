// ViewController.m
// This contains the private interface and implementation of the ViewController class.

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <opencv2/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>
#import <opencv2/features2d.hpp>
#import <opencv2/xfeatures2d.hpp>
#import <opencv2/xphoto.hpp>

#pragma clang diagnostic pop

#import "ViewController.h"

using namespace std;
using namespace cv;

// ************************************************************************************

// The arc4random() function returns a random 32-bit integer in the range of 0 to 2^32-1 (or 0x100000000). The  first time it is called, the function automatically seeds the random number generator.
#define RAND_0_1() ((double)arc4random() / 0x100000000)

@interface ViewController () {
  cv::Mat originalMat;
  cv::Mat updatedMat;
  cv::Mat grayMat;
}
  
  @property IBOutlet UIImageView *imageView;
  @property NSTimer *timer;
  
- (void) updateImage;
  
  @end

// ************************************************************************************

@implementation ViewController
  
- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Define colors for drawing.
  cv::Scalar delaunay_color(255, 255, 255), points_color(255, 255, 255);
  
  // Load a UIImage from a resource file.
  UIImage *originalImage = [UIImage imageNamed:@"Fiddle.png"];
  
  // Convert the UIImage to a cv::Mat.
  UIImageToMat(originalImage, originalMat);
  
  // Rectangle to be used with Subdiv2D
  cv::Size size = originalMat.size();
  cv::rectangle(originalMat, cvPoint(0, 0), cvPoint(size.width, size.height), 155);
  // cv::Rect rect;
  
  // Subdiv2D(rect);
  // Points for storage
  std::vector<cv::Point2f> points;
  
  // SIFT only works on Grayscale
  cv::cvtColor(originalMat, grayMat, cv::COLOR_BGR2GRAY);
  
  // Declare SIFT object for detection and keypoints vector for storage
  cv::Ptr<cv::xfeatures2d::SIFT> sift = cv::xfeatures2d::SIFT::create();
  std::vector<KeyPoint> keypoints;
  cv::Mat description;
  
  sift->detect(grayMat, keypoints);
  sift->compute(grayMat, keypoints, description);
  
  cv::KeyPoint::convert(keypoints, points);
  
  // Draw keypoints on image!
  cv::drawKeypoints(grayMat, keypoints, grayMat, cv::Scalar::all(-1), DrawMatchesFlags::DRAW_RICH_KEYPOINTS);
  
  // Render circles on keypoints!
    for (std::vector<Point2f>::iterator it = points.begin(); it != points.end(); it++) {
      cv::circle(grayMat, *it, 10, points_color, 2);
      subdiv.insert(*it);
    }
  
  // Insert points into subdiv
  renderDelaunay(grayMat, subdiv, delaunay_color);
  
  self.imageView.image = MatToUIImage(grayMat);
  
  // grayMat = description; This is pretty wack!
  originalMat = grayMat;
  
  
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
  self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
  
  // cv::circle(originalMat, cvPoint2D32f(400, 400), 100, 155, 5);
  // cv::line(originalMat, cvPoint2D32f(600, 600), cvPoint2D32f(700, 700), 155, 3.5);
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
  
static void renderDelaunay(cv::Mat& img, Subdiv2D& subdiv, cv::Scalar delaunay_color) {
  std::vector<Vec6f> triangleList;
  subdiv.getTriangleList(triangleList);
  std::vector<cv::Point2f> pt(3);
  cv::Size size = img.size();
  cv::Rect rect(0, 0, size.width, size.height);
  
  for (size_t i = 0; i < triangleList.size(); i++) {
    Vec6f t = triangleList[i];
    pt[0] = cv::Point2f(cvRound(t[0]), cvRound(t[1]));
    pt[1] = cv::Point2f(cvRound(t[2]), cvRound(t[3]));
    pt[2] = cv::Point2f(cvRound(t[4]), cvRound(t[5]));
    
    // Draw rectangles completely inside the image.
    if (rect.contains(pt[0]) && rect.contains(pt[1]) && rect.contains(pt[2])) {
      line(img, pt[0], pt[1], delaunay_color, 1, CV_AA, 0);
      line(img, pt[1], pt[2], delaunay_color, 1, CV_AA, 0);
      line(img, pt[2], pt[0], delaunay_color, 1, CV_AA, 0);
    }
  }
}
  
  
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}
  
  @end
