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
cv::Mat savedImage;

cv::Vec3b intensity;
cv::Scalar color;

// View loaded, off we go!
- (void)viewDidLoad {
    [super viewDidLoad];
    [self renderMethod:@"lines"];
    
    // *************************************************************
    // * Utility
    
    // Load a UIImage from a resource file.
    UIImage *originalImage = [UIImage imageNamed:@"ZeBum.jpg"];
    
    // Convert the UIImage to a cv::Mat.
    UIImageToMat(originalImage, originalStillMat);
    NSLog(@"*** onLoad: %s %dx%d \n", type2str(originalStillMat.type()).c_str(), originalStillMat.cols, originalStillMat.rows);
    
    
    self.videoCamera = [[VideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetMedium;
    self.videoCamera.letterboxPreview = YES;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
    
    // *************************************************************
    // * Basic Image Processing
    //    switch(originalMat.type()) {
    //        case CV_8UC1:
    //            // The cv::Mat is in grayscale format. Convert to RGB.
    //            cv::cvtColor(originalMat, originalMat, cv::COLOR_GRAY2RGB);
    //            break;
    //
    //        case CV_8UC4:
    //            // The cv::Mat is in RGBA format. Convert to RGB.
    //            cv::cvtColor(originalMat, originalMat, cv::COLOR_RGBA2RGB);
    //            break;
    //
    //        case CV_8UC3:
    //            // The cv::Mat is in RGB format.
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

- (IBAction)onLinesPressed:(id)sender {
    [self renderMethod:@"lines"];
}

- (IBAction)onPolyPressed:(id)sender {
    [self renderMethod:@"polygons"];
}

- (void)renderMethod:(NSString *)m {
    if ([m isEqualToString:@"lines"]) {
        NSLog(@"Rendering only lines and circles.");
        self.renderPolygonsOnly = false;
        self.renderLinesOnly = true;
    } else if ([m isEqualToString:@"polygons"]) {
        NSLog(@"Rendering only polygons.");
        self.renderPolygonsOnly = true;
        self.renderLinesOnly = false;
    }
}

// Refresh and update the imageView
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
        //        cv::cvtColor(originalStillMat, updatedStillMatGray, cv::COLOR_RGBA2GRAY);
        //        [self processImage:updatedStillMatGray];
        // NSLog(@"process: %s %dx%d \n", type2str(originalStillMat.type()).c_str(), originalStillMat.cols, originalStillMat.rows);
        [self processImage:originalStillMat];
        image = MatToUIImage(originalStillMat);
        updatedVideoMatRGBA = originalStillMat.clone();
        
        
        // Display a still image into the view if the camera isn't running!
        self.imageView.image = image;
    }
}

- (void)processImage:(cv::Mat &)finalMat {
    cv::Mat mat = finalMat.clone();
    
    // *************************************************************
    // * Feature Detection (SIFT)
    
    // nfeatures	The number of best features to retain. The features are ranked by their scores (measured in SIFT algorithm as the local contrast)
    // nOctaveLayers	The number of layers in each octave. 3 is the value used in D. Lowe paper. The number of octaves is computed automatically from the image resolution.
    // contrastThreshold	The contrast threshold used to filter out weak features in semi-uniform (low-contrast) regions. The larger the threshold, the less features are produced by the detector.
    // edgeThreshold	The threshold used to filter out edge-like features. Note that the its meaning is different from the contrastThreshold, i.e. the larger the edgeThreshold, the less features are filtered out (more features are retained).
    // sigma	The sigma of the Gaussian applied to the input image at the octave #0. If your image is captured with a weak camera with soft lenses, you might want to reduce the number.
    
    int nF = 70, nOct = 2;
    double cT = 0.06, eT = 20, s = 2.6;
    
    NSLog(@"Before SIFT: %s %dx%d \n", type2str(mat.type()).c_str(), mat.cols, mat.rows);
    
    // Construct SIFT object
    // cv::Ptr<cv::xfeatures2d::SIFT> sift = cv::xfeatures2d::SIFT::create(nF, nOct, cT, eT, s);
    cv::Ptr<cv::xfeatures2d::SIFT> sift = cv::xfeatures2d::SIFT::create();
    
    // Find keypoints in the image
    std::vector<KeyPoint> keypoints;
    sift->detect(mat, keypoints);
    
    // Compute descriptors
    cv::Mat descriptors;
    sift->compute(mat, keypoints, descriptors);
    
    // Draw keypoints on image w/ size of keypoint and orientation!
    //     cv::drawKeypoints(bwCopy, keypoints, bwCopy, cv::Scalar::all(-1), DrawMatchesFlags::DRAW_RICH_KEYPOINTS);
    
    // *************************************************************
    // * Triangulation
    
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
        subdiv.insert(*it); // cv::circle(mat, *it, 10, cv::Scalar(255, 255, 255), 2);
    }
    
    // Render Delaunay Triangles and Voronoi Diagram
    NSLog(@"Before Triangulation: %s %dx%d \n", type2str(mat.type()).c_str(), mat.cols, mat.rows);
    //    color[0] = rand() & 255; color[1] = rand() & 155; color[2] = rand() & 155; color[3] = 205;
    
    // Vertices of triangulation
    std::vector<cv::Point> tVerts(3);
    vector<vector<Point2f>> facets;
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
        
        Vec2f c;
        if (!centersList.empty()) c = centersList[i];
        
        int x = int(c[0]);
        int y = int(c[1]);
        
        // Stay inside bounding rectangle
        if (rect.contains(cv::Point(x, y))) {
//        if (x < size.width && x > 0 && y < size.height && y > 0) {
            intensity = mat.at<cv::Vec3b>(cv::Point(x, y));
            uchar b = intensity.val[0];
            uchar g = intensity.val[1];
            uchar r = intensity.val[2];
            NSLog(@"x: %d, y: %d \t B: %d, G: %d, R: %d", x, y, b, g, r);
            
            // RGBA <- BGR
            color[0] = r;
            color[1] = g;
            color[2] = b;
            color[3] = 155;
            
            if (self.renderPolygonsOnly) cv::fillConvexPoly(finalMat, tVerts, color, LINE_AA, 0);
            
            if (self.renderLinesOnly) {
                line(finalMat, tVerts[0], tVerts[1], color, 1, CV_AA, 0);
                line(finalMat, tVerts[1], tVerts[2], color, 1, CV_AA, 0);
                line(finalMat, tVerts[2], tVerts[0], color, 1, CV_AA, 0);
                // cv::circle(finalMat, cv::Point(x, y), 3, color, 2);
            }
        }
    }
    
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
    
    if (self.saveNextFrame) {
        // The video frame, 'mat', is not safe for long-running
        // operations such as saving to file. Thus, we copy its
        // data to another cv::Mat first.
        UIImage *image;
        finalMat.copyTo(savedImage);
        image = MatToUIImage(savedImage);
        [self saveImage:image];
        self.saveNextFrame = NO;
    }
}

- (void)processImageHelper:(cv::Mat &)mat {
    
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

- (IBAction)onSaveButtonPressed {
    [self startBusyMode];
    if (self.videoCamera.running) {
        self.saveNextFrame = YES;
    } else {
        [self saveImage:self.imageView.image];
    }
}

- (void)saveImage:(UIImage *)image {
    // Try to save the image to a temporary file.
    NSString *outputPath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.png"];
    if (![UIImagePNGRepresentation(image) writeToFile:outputPath atomically:YES]) {
        // Show an alert describing the failure.
        NSLog(@"*** Save failed. ***");
        // [self showSaveImageFailureAlertWithMessage:@"The image could not be saved to the temporary directory."];
         return;
    }
    
    // Try to add the image to the Photos library.
    NSURL *outputURL = [NSURL URLWithString:outputPath];
    PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    [photoLibrary performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:outputURL];
    } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            // Show an alert describing the success, with sharing options.
            // [self showSaveImageSuccessAlertWithImage:image];
        } else {
            // Show an alert describing the failure.
            // [self showSaveImageFailureAlertWithMessage: error.localizedDescription];
        }
    }];
}

- (void)startBusyMode {
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.activityIndicatorView startAnimating];
//        for (UIBarItem *item in self.toolbar.items) {
//            item.enabled = NO;
//        }
    });
}

- (void)stopBusyMode {
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.activityIndicatorView stopAnimating];
//        for (UIBarItem *item in self.toolbar.items) {
//            item.enabled = YES;
//        }
    });
}

string type2str(int type) {
    string r;
    
    uchar depth = type & CV_MAT_DEPTH_MASK;
    uchar chans = 1 + (type >> CV_CN_SHIFT);
    
    switch ( depth ) {
        case CV_8U:  r = "8U"; break;
        case CV_8S:  r = "8S"; break;
        case CV_16U: r = "16U"; break;
        case CV_16S: r = "16S"; break;
        case CV_32S: r = "32S"; break;
        case CV_32F: r = "32F"; break;
        case CV_64F: r = "64F"; break;
        default:     r = "User"; break;
    }
    
    r += "C";
    r += (chans+'0');
    
    return r;
}

// *************************************************************
// Dispose of any resources that can be recreated.
- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

// ************************************************************************************
