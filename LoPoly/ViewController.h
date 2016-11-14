// ViewController.h
// Prayash Thapa

// This defines the public interface of a ViewController class. This class is
// responsible for managing the application's main scene, which we saw in Main.Storyboard.

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIScrollViewDelegate>
  // Main image view which displays the output image
  @property (weak, nonatomic) IBOutlet UIImageView *imageView;

  // A container for imageView that allows pinch gestures
  @property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

  // Intervalometer to keep updateImage going
  @property NSTimer *timer;

  // Updates image colors and such.
  - (void) updateImage;

@end

