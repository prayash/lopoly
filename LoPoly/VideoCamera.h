//
//  VideoCamera.h
//  LoPoly
//
//  Created by Prayash Thapa on 11/29/16.
//  Copyright © 2016 Prayash Thapa. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <opencv2/videoio/cap_ios.h>

#pragma clang diagnostic pop

@interface VideoCamera : CvVideoCamera

@property BOOL letterboxPreview;
@property (nonatomic, retain) CALayer *customPreviewLayer;

- (void)setPointOfInterestInParentViewSpace:(CGPoint)point;

@end
