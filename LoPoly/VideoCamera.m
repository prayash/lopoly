//
//  VideoCamera.m
//  LoPoly
//
//  Created by Prayash Thapa on 11/29/16.
//  Copyright © 2016 Prayash Thapa. All rights reserved.
//

#import "VideoCamera.h"

@implementation VideoCamera

@synthesize customPreviewLayer = _customPreviewLayer;

// Override buggy OpenCV resolution issues
- (int)imageWidth {
    AVCaptureVideoDataOutput *output = [self.captureSession.outputs lastObject];
    NSDictionary *videoSettings = [output videoSettings];
    int videoWidth = [[videoSettings objectForKey:@"Width"] intValue];
    return videoWidth;
}

// Override buggy OpenCV resolution issues
- (int)imageHeight {
    AVCaptureVideoDataOutput *output = [self.captureSession.outputs lastObject];
    NSDictionary *videoSettings = [output videoSettings];
    int videoWidth = [[videoSettings objectForKey:@"Height"] intValue];
    return videoWidth;
}

- (void)updateSize {
    // Nothing
}

- (void)layoutPreviewLayer {
    if (self.parentView != nil) {
        
        // Center video preview.
        self.customPreviewLayer.position = CGPointMake(
            0.5 * self.parentView.frame.size.width,
            0.5 * self.parentView.frame.size.height);
        
        // Find the video's aspect ratio.
        CGFloat videoAspectRatio = self.imageWidth / (CGFloat)self.imageHeight;
        
        // Scale the video preview while maintaining its aspect ratio.
        CGFloat boundsW;
        CGFloat boundsH;
        
        if (self.imageHeight > self.imageWidth) {
            if (self.letterboxPreview) {
                boundsH = self.parentView.frame.size.height;
                boundsW = boundsH * videoAspectRatio;
            } else {
                boundsW = self.parentView.frame.size.width;
                boundsH = boundsW / videoAspectRatio;
            }
        } else {
            if (self.letterboxPreview) {
                boundsW = self.parentView.frame.size.width;
                boundsH = boundsW / videoAspectRatio;
            } else {
                boundsH = self.parentView.frame.size.height;
                boundsW = boundsH * videoAspectRatio;
            }
        }
        
        self.customPreviewLayer.bounds = CGRectMake(0.0, 0.0, boundsW, boundsH);
    }
}

- (void)setPointOfInterestInParentViewSpace:(CGPoint)parentViewPoint {
    if (!self.running) return;
    
    CGFloat cWidth = self.customPreviewLayer.bounds.size.width;
    CGFloat cHeight = self.customPreviewLayer.bounds.size.height;
    
    // Find current capture device
    NSArray *captureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice;
    
    for (captureDevice in captureDevices) {
        if (captureDevice.position == self.defaultAVCaptureDevicePosition) break;
    }
    
    BOOL canSetFocus = [captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && captureDevice.isFocusPointOfInterestSupported;
    
    BOOL canSetExposure = [captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose] && captureDevice.isExposurePointOfInterestSupported;
    
    // Do nothing if they aren't supported
    if (!canSetFocus && !canSetExposure) return;
    
    if (![captureDevice lockForConfiguration:nil]) return;
    
    // Find the preview's offset relative to the parent view
    CGFloat offsetX = 0.5 * (self.parentView.bounds.size.width - self.customPreviewLayer.bounds.size.width);
    CGFloat offsetY = 0.5 * (self.parentView.bounds.size.height - self.customPreviewLayer.bounds.size.height);
    
    // Find the focus coordinates, proportional to the preview size.
    CGFloat focusX = (parentViewPoint.x - offsetX) / cWidth;
    CGFloat focusY = (parentViewPoint.y - offsetY) / cHeight;
    
    if (focusX < 0.0 || focusX > 1.0 || focusY < 0.0 || focusY > 1.0) {
        // The point is outside the preview
        return;
    }
    
    // Adjust the focus coordinates based on the orientation
    // They should be in the landscape-right coordinate system
    
    switch (self.defaultAVCaptureVideoOrientation) {
        case AVCaptureVideoOrientationPortraitUpsideDown: {
            CGFloat oldFocusX = focusX;
            focusY = oldFocusX;
            break;
        }
            
        case AVCaptureVideoOrientationLandscapeLeft: {
            focusX = 1.0 - focusX;
            focusY = 1.0 - focusY;
            break;
        }
        
        case AVCaptureVideoOrientationLandscapeRight: {
            // Do nothing.
            break;
        }
            
        // Portrait
        default: {
            CGFloat oldFocusX = focusX;
            focusX = focusY;
            focusY = 1.0 - oldFocusX;
            break;
        }
    }
    
    if (self.defaultAVCaptureDevicePosition == AVCaptureDevicePositionFront) {
        // De-mirror the X coordinate
        focusX = 1.0 - focusX;
    }
    
    CGPoint focusPoint = CGPointMake(focusX, focusY);
    
    if (canSetFocus) {
        // Auto-focus on the selected point
        captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
        captureDevice.focusPointOfInterest = focusPoint;
    }
    
    if (canSetExposure) {
        captureDevice.exposureMode = AVCaptureExposureModeAutoExpose;
        captureDevice.exposurePointOfInterest = focusPoint;
    }
    
    [captureDevice unlockForConfiguration];
}
@end

