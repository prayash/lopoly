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

@interface ViewController ()
@end

// ************************************************************************************

@implementation ViewController

  cv::Mat originalMat;
  cv::Mat updatedMat;
  cv::Mat grayMat;

- (void) viewDidLoad {
  [super viewDidLoad];
  
  // * ScrollView which controls pinch zoom interaction
  [self.scrollView setMinimumZoomScale: 1.0f];
  [self.scrollView setMaximumZoomScale: 5.0f];
  [self.scrollView setClipsToBounds: YES];
  
  // Load a UIImage from a resource file.
  UIImage *originalImage = [UIImage imageNamed:@"ZeBum.jpg"];
  
  // Convert the UIImage to a cv::Mat.
  UIImageToMat(originalImage, originalMat);

  // Create a grayscale copy
  cv::cvtColor(originalMat, grayMat, cv::COLOR_BGR2GRAY);
  
  // *************************************************************
  // * Feature Detection (SIFT)

  // Declare SIFT object for detection and a keypoints vector for storage
  cv::Ptr<cv::xfeatures2d::SIFT> sift = cv::xfeatures2d::SIFT::create();
  std::vector<KeyPoint> keypoints;
  cv::Mat descriptors;
  
  sift->detect(grayMat, keypoints);
  sift->compute(grayMat, keypoints, descriptors);
  
  // Points for storage
  std::vector<cv::Point2f> points;
  cv::KeyPoint::convert(keypoints, points);
  
  // Draw keypoints on image!
  cv::drawKeypoints(grayMat, keypoints, grayMat, cv::Scalar::all(-1), DrawMatchesFlags::DRAW_RICH_KEYPOINTS);
  
  // *************************************************************
  // * Delaunay Triangulation
  
  // Rectangle to be used with Subdiv2D
  cv::Size size = originalMat.size();
  cv::Rect rect(0, 0, size.width, size.height);
  
  cv::Subdiv2D subdiv;
  subdiv.initDelaunay(rect);
  
  // Insert key points into subdivision
  for (std::vector<Point2f>::iterator it = points.begin(); it != points.end(); it++) {
    subdiv.insert(*it);
    // cv::circle(grayMat, *it, 10, points_color, 2);
  }
  
  // Define colors for drawing.
  cv::Scalar delaunay_color(255, 255, 255), points_color(255, 255, 255);
  
  // Render Delaunay Triangles
  renderDelaunay(grayMat, subdiv, delaunay_color);
  
  // *************************************************************
  // * Voronoi Diagram
  
  cv::Mat voronoi = cv::Mat::zeros(grayMat.rows, grayMat.cols, CV_8UC3);
  // renderVoronoi(voronoi, subdiv);
  
  // Cast image to UIImage
  self.imageView.image = MatToUIImage(grayMat);
  
  // grayMat = descriptors; This is pretty wack!
  originalMat = grayMat;
  
  
  // *************************************************************
  // * Basic Image Processing
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
  
  // Call an update method every 5 seconds.
  // NSTimer only res callbacks when the app is in the foreground. This behavior is
  // convenient for our purposes because we only want to update the image when it is visible.
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

// Render Delaunay polygons
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

// Render Voronoi diagram
static void renderVoronoi(cv::Mat& img, Subdiv2D& subdiv) {
  vector<vector<Point2f>> facets;
  vector<Point2f> centers;
  subdiv.getVoronoiFacetList(vector<int>(), facets, centers);
  
  vector<Point2f> ifacet;
  vector<vector<Point2f> > ifacets(1);
  
  for(size_t i = 0; i < facets.size(); i++) {
    ifacet.resize(facets[i].size());
    
    for (size_t j = 0; j < facets[i].size(); j++) {
      ifacet[j] = facets[i][j];
    }
    
    Scalar color;
    color[0] = rand() & 255;
    color[1] = rand() & 255;
    color[2] = rand() & 255;
    fillConvexPoly(img, ifacet, color, 8, 0);
    
    ifacets[0] = ifacet;
    polylines(img, ifacets, true, Scalar(), 1, CV_AA, 0);
    circle(img, centers[i], 3, Scalar(), CV_FILLED, CV_AA, 0);
  }
}
  

- (void) didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return self.imageView;
}
  
@end
