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
    
    // Create an OpenGL ES context and assign it to the view loaded from storyboard
//    GLKView *glkView = (GLKView *)self.view;
//    glkView.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
//    EAGLContext.setCurrentContext(glkView.context);
    
    
    // Configure renderbuffers created by the view
    //glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    // view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    // view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    
    // Enable multisampling
    // view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    // EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    // [EAGLContext setCurrentContext: context];
    
    
    // Load a UIImage from a resource file.
    // UIImage *originalImage = [UIImage imageNamed:@"ZeBum.jpg"];
    UIImage *originalStillImage = [UIImage imageNamed:@"ZeBum.jpg"];
    
    // Convert the UIImage to a cv::Mat.
    // UIImageToMat(originalImage, originalMat);
    UIImageToMat(originalStillImage, originalStillMat);
    
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.letterboxPreview = YES;
    self.videoCamera.delegate = self;
    
    // *************************************************************
    // * Voronoi Diagram
    
    //cv::Mat voronoi = cv::Mat::zeros(grayMat.rows, grayMat.cols, CV_8UC3);
    // renderVoronoi(voronoi, subdiv);
    
    // Cast image to UIImage and display it
    // self.imageView.image = MatToUIImage(grayMat);
    
    // grayMat = descriptors; // This is pretty wack!
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
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    [self.videoCamera start];
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
    
    // Convert to grayscale for feature detection
    cv::cvtColor(mat, mat, cv::COLOR_BGR2GRAY);
    
    // Construct SIFT object
    cv::Ptr<cv::xfeatures2d::SIFT> sift = cv::xfeatures2d::SIFT::create();
    
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
        // cv::circle(grayMat, *it, 10, points_color, 2);
    }
    
    // Define colors for drawing.
    cv::Scalar hue(255, 255, 255, 0.1f);
    
    // Render Delaunay Triangles
    renderDelaunay(mat, subdiv, hue);
    
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
    // TODO: Implement in Chapter 3.
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

- (void) drawRect:(CGRect)rect {
    // Clear the framebuffer
    glClearColor(0.0f, 0.0f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

// Render Delaunay triangles
static void renderDelaunay(cv::Mat& img, Subdiv2D& subdiv, cv::Scalar color) {
    
    std::vector<cv::Point2f> pt(3);
    cv::Size size = img.size();
    cv::Rect rect(0, 0, size.width, size.height);
    
    std::vector<Vec6f> triangleList;
    subdiv.getTriangleList(triangleList);
    
    for (size_t i = 0; i < triangleList.size(); i++) {
        Vec6f t = triangleList[i];
        pt[0] = cv::Point2f(cvRound(t[0]), cvRound(t[1]));
        pt[1] = cv::Point2f(cvRound(t[2]), cvRound(t[3]));
        pt[2] = cv::Point2f(cvRound(t[4]), cvRound(t[5]));
        
        // Draw rectangles completely inside the image.
        //    if (rect.contains(pt[0]) && rect.contains(pt[1]) && rect.contains(pt[2])) {
        line(img, pt[0], pt[1], color, 1, LINE_AA, 0);
        line(img, pt[1], pt[2], color, 1, LINE_AA, 0);
        line(img, pt[2], pt[0], color, 1, LINE_AA, 0);
        //    }
    }
}

// *************************************************************
// Dispose of any resources that can be recreated.
- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

// ************************************************************************************
