// AppDelegate.h
// Prayash Thapa

// This defines the public interface of an AppDelegate class. This class is responsible for
// managing the application's life cycle.

#import <UIKit/UIKit.h>
#import "LGSideMenuController.h"

#define kMainViewController                            (MainViewController *)[UIApplication sharedApplication].delegate.window.rootViewController



@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

