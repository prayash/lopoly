// LoPoly
// ViewController.m
// Prayash Thapa

// Main Implementation

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <opencv2/core.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/imgcodecs.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/features2d.hpp>
#import <opencv2/xfeatures2d.hpp>
#import <opencv2/xphoto.hpp>

#pragma clang diagnostic pop

#import "ViewController.h"
#import "VideoCamera.h"

#import <Photos/Photos.h>
#import <Social/Social.h>

using namespace std;
using namespace cv;

// ************************************************************************************

// The arc4random() function returns a random 32-bit integer.
// The first time it is called, the function automatically seeds the random number generator.
#define RAND_0_1() ((double)arc4random() / 0x100000000)

// ************************************************************************************

@implementation ViewController

    cv::Mat originalMat;
    cv::Mat updatedMat;
    cv::Mat grayMat;

    cv::Mat originalStillMat;
    cv::Mat updatedStillMatGray;
    cv::Mat updatedStillMatRGBA;
    cv::Mat updatedVideoMatGray;
    cv::Mat updatedVideoMatRGBA;

// View loaded, off we go!
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // *************************************************************
    // * Utility
 
    // Load a UIImage from a resource file.
    // UIImage *originalImage = [UIImage imageNamed:@"ZeBum.jpg"];
    UIImage *originalStillImage = [UIImage imageNamed:@"ZeBum.jpg"];
    
    // Convert the UIImage to a cv::Mat.
    // UIImageToMat(originalImage, originalMat);
    UIImageToMat(originalStillImage, originalStillMat);
    
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.letterboxPreview = YES;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = YES;
    self.videoCamera.delegate = self;
    
    originalMat = grayMat;
    
    // *************************************************************
    // * Drawing
    
    // cv::circle(originalMat, cvPoint2D32f(400, 400), 100, 155, 5);
    // cv::line(originalMat, cvPoint2D32f(600, 600), cvPoint2D32f(700, 700), 155, 3.5);
    
    
    // *************************************************************
    // * Basic Image Processing
//    switch(originalMat.type()) {
//        case CV_8UC1:
//            // The cv::Mat is in grayscale format.
//            // Convert to RGB.
//            cv::cvtColor(originalMat, originalMat, cv::COLOR_GRAY2RGB);
//            break;
//            
//        case CV_8UC4:
//            // The cv::Mat is in RGBA format.
//            // Convert to RGB.
//            cv::cvtColor(originalMat, originalMat, cv::COLOR_RGBA2RGB);
//            
//            // Adjust white balance.
//#ifdef WITH_OPENCV_CONTRIB
//            cv::xphoto::WhiteBalancer *wb;
//            wb->balanceWhite(originalMat, originalMat);
//#endif
//            break;
//            
//        case CV_8UC3:
//            // The cv::Mat is in RGB format.
//#ifdef WITH_OPENCV_CONTRIB
//            wb->balanceWhite(originalMat, originalMat);
//#endif
//            break;
//            
//        default:
//            break;
//    }
    
    // Call update every 5 seconds (only when the app is in the foreground).
    // self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:true];

#if (TARGET_IPHONE_SIMULATOR)
    NSLog(@"Running on emulator. No camera available.");
    [self refresh];
#else
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    [self.videoCamera start];
#endif
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
            
        default:
            self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    // Refresh camera
    // [self refresh];
}

- (IBAction)onTapToSetPointOfInterest:(UITapGestureRecognizer *)tapGesture {
    if (tapGesture.state == UIGestureRecognizerStateEnded) {
        if (self.videoCamera.running) {
            CGPoint tapPoint = [tapGesture locationInView: self.imageView];
            [self.videoCamera setPointOfInterestInParentViewSpace: tapPoint];
        }
    }
}

- (void)refresh {
    if (self.videoCamera.running) {
        // Hide the still image.
        self.imageView.image = nil;
        
        // Restart the video.
        [self.videoCamera stop];
        [self.videoCamera start];
    } else {
        // Refresh the still image.
        UIImage *image;
        if (self.videoCamera.grayscaleMode) {
            cv::cvtColor(originalStillMat, updatedStillMatGray, cv::COLOR_RGBA2GRAY);
            [self processImage:updatedStillMatGray];
            image = MatToUIImage(updatedStillMatGray);
        } else {
            cv::cvtColor(originalStillMat, updatedStillMatRGBA, cv::COLOR_RGBA2BGRA);
            [self processImage:updatedStillMatRGBA];
            cv::cvtColor(updatedStillMatRGBA, updatedStillMatRGBA, cv::COLOR_BGRA2RGBA);
            image = MatToUIImage(updatedStillMatRGBA);
        }
        self.imageView.image = image;
    }
}

- (void)processImage:(cv::Mat &)mat {
    
//    // Do some OpenCV stuff with the image
//    cv::Mat image_copy;
//    cv::cvtColor(mat, image_copy, CV_BGRA2BGR);
//    
//    // invert image
//    bitwise_not(image_copy, image_copy);
//    cv::cvtColor(image_copy, mat, CV_BGR2BGRA);
    
    // *************************************************************
    // * Feature Detection (SIFT)
    
    // nfeatures	The number of best features to retain. The features are ranked by their scores (measured in SIFT algorithm as the local contrast)
    // nOctaveLayers	The number of layers in each octave. 3 is the value used in D. Lowe paper. The number of octaves is computed automatically from the image resolution.
    // contrastThreshold	The contrast threshold used to filter out weak features in semi-uniform (low-contrast) regions. The larger the threshold, the less features are produced by the detector.
    // edgeThreshold	The threshold used to filter out edge-like features. Note that the its meaning is different from the contrastThreshold, i.e. the larger the edgeThreshold, the less features are filtered out (more features are retained).
    // sigma	The sigma of the Gaussian applied to the input image at the octave #0. If your image is captured with a weak camera with soft lenses, you might want to reduce the number.
    
    int nF = 70, nOct = 2;
    double cT = 0.06, eT = 20, s = 2.6;

    // Construct SIFT object
    // cv::Ptr<cv::xfeatures2d::SIFT> sift = cv::xfeatures2d::SIFT::create(nF, nOct, cT, eT, s);
    cv::Ptr<cv::xfeatures2d::SIFT> sift = cv::xfeatures2d::SIFT::create();

    // Convert to grayscale for feature detection
    if (originalMat.type() != CV_8UC1) cv::cvtColor(mat, mat, cv::COLOR_BGR2GRAY);
    
    // Find keypoints in the image
    std::vector<KeyPoint> keypoints;
    sift->detect(mat, keypoints);
    
    // Compute descriptors
    cv::Mat descriptors;
    sift->compute(mat, keypoints, descriptors);
    
    // Draw keypoints on image w/ size of keypoint and orientation!
    // cv::drawKeypoints(mat, keypoints, mat, cv::Scalar::all(-1), DrawMatchesFlags::DRAW_RICH_KEYPOINTS);

    // *************************************************************
    // * Delaunay Triangulation
    
    // Input dimensions
    cv::Size size = mat.size();
    
    // Rectangle to be used for Subdiv2D
    cv::Rect rect(0, 0, size.width, size.height);
    
    // Creates a new empty Delaunay subdivision
    cv::Subdiv2D subdiv;
    subdiv.initDelaunay(rect);
    
    // Convert keypoints and store their locations in the points vector
    std::vector<cv::Point2f> points;
    cv::KeyPoint::convert(keypoints, points);
    
    // Insert key points into subdivision
    for (std::vector<Point2f>::iterator it = points.begin(); it != points.end(); it++) {
        subdiv.insert(*it);
        // cv::circle(mat, *it, 10, cv::Scalar(255, 255, 255), 2);
    }
    
    // Define colors for drawing.
    cv::Scalar hue(255, 255, 255);
    
    // Convert to color because we like colors
    cv::cvtColor(mat, mat, cv::COLOR_GRAY2BGR);
    
    // Render Delaunay Triangles and Voronoi Diagram
    renderDelaunay(mat, subdiv, hue);
    // renderVoronoi(mat, subdiv);
    
    if (self.videoCamera.running) {
        switch (self.videoCamera.defaultAVCaptureVideoOrientation) {
            case AVCaptureVideoOrientationLandscapeLeft:
            case AVCaptureVideoOrientationLandscapeRight:
                // The landscape video is captured upside-down.
                // Rotate it by 180 degrees.
                cv::flip(mat, mat, -1);
                break;
            default:
                break;
        }
    }
    
    [self processImageHelper:mat];
    
    if (self.saveNextFrame) {
        // The video frame, 'mat', is not safe for long-running
        // operations such as saving to file. Thus, we copy its
        // data to another cv::Mat first.
        UIImage *image;
        if (self.videoCamera.grayscaleMode) {
            mat.copyTo(updatedVideoMatGray);
            image = MatToUIImage(updatedVideoMatGray);
        } else {
            cv::cvtColor(mat, updatedVideoMatRGBA, cv::COLOR_BGRA2RGBA);
            image = MatToUIImage(updatedVideoMatRGBA);
        }
        [self saveImage:image];
        self.saveNextFrame = NO;
    }
}

- (IBAction)onColorModeSelected:(UISegmentedControl *)segmentedControl {
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            self.videoCamera.grayscaleMode = NO;
            break;
        default:
            self.videoCamera.grayscaleMode = YES;
            break;
    }
    [self refresh];
}

- (IBAction)onSwitchCameraButtonPressed {
    
    if (self.videoCamera.running) {
        switch (self.videoCamera.defaultAVCaptureDevicePosition) {
            case AVCaptureDevicePositionFront:
                self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
                [self refresh];
                break;
            default:
                [self.videoCamera stop];
                [self refresh];
                break;
        }
    } else {
        // Hide the still image.
        self.imageView.image = nil;
        
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        [self.videoCamera start];
    }
}

- (void)processImageHelper:(cv::Mat &)mat {
    // Ain't nuthin' but a g-thang baybay.
}

// Method that processes the final image and renders to imageView
- (void)updateImage {
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

// Render Delaunay triangles
static void renderDelaunay(cv::Mat& img, Subdiv2D& subdiv, cv::Scalar color) {
    
    std::vector<cv::Point> tVerts(3);
    vector<vector<Point2f> > facets;
    vector<Point2f> centers;
    
    // Get all triangles!
    std::vector<Vec6f> triangleList;
    subdiv.getTriangleList(triangleList);
    
    // Get center values
    std::vector<Point2f> centersList;
    subdiv.getVoronoiFacetList(vector<int>(), facets, centersList);
    
    // This is where the mesh gets colored
    for (size_t i = 0; i < triangleList.size(); i++) {
        
        // Store triangle vertices into an array
        Vec6f t = triangleList[i];
        tVerts[0] = cv::Point(cvRound(t[0]), cvRound(t[1]));
        tVerts[1] = cv::Point(cvRound(t[2]), cvRound(t[3]));
        tVerts[2] = cv::Point(cvRound(t[4]), cvRound(t[5]));
        
        
        // Sample the color in the Voronoi center
        cv::Scalar color;
        Vec2f c = centersList[i];
        

        // Sample BGR values at each x,y center value of each triangle
        color[2] = cv::Vec3b(c[1], c[0])[0];  //img.at<cv::Vec3b>(y,x)[0]; //rand() & 255;
        color[1] = cv::Vec3b(c[1], c[0])[1];  //img.at<cv::Vec3b>(y,x)[1]; //rand() & 155;
        color[0] = cv::Vec3b(c[1], c[0])[2];  //img.at<cv::Vec3b>(y,x)[2]; //rand() & 155;
        
        // Methods to the right possibly extract pixel at points on image.. result is all black though

        // Fill triangles with sampled color
        //cv::Scalar color(b,g,r);
        
        fillConvexPoly(img, tVerts, color, 8, 0);
    }
}

// *************************************************************
// Dispose of any resources that can be recreated.
- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

// ************************************************************************************
