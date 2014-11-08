//
//  LMAppDelegate.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMAppDelegate.h"

#import "LMROMBrowserController.h"

// TODO: LM: Better save UI to allow for multiple slots
// TODO: LM: save/show screenshots for save states in the save state manager

@implementation LMAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)dealloc
{
  [_window release];
  [_viewController release];
  [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if TARGET_IPHONE_SIMULATOR
  // where are we?
  NSLog(@"\nDocuments Directory:\n%@\n\n", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);
#endif
  
  self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
  
  LMROMBrowserController* romBrowser = [[LMROMBrowserController alloc] init];
  UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:romBrowser];
  
  UINavigationBar* navigationbar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, -100, nav.navigationBar.frame.size.width, 100)];
  navigationbar.tag = 1000;
  navigationbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
  navigationbar.backgroundColor = [UIColor clearColor];
  
  UIImageView* imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, nav.navigationBar.frame.size.width, 100)];
  imageview.tag = 1001;
  imageview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  imageview.contentMode = UIViewContentModeScaleAspectFill;
  imageview.clipsToBounds = YES;
  imageview.layer.magnificationFilter = kCAFilterNearest;
  imageview.alpha = 0.9;
  [navigationbar addSubview:imageview];
  [imageview release];
  
  UIImageView* gradientimageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, nav.navigationBar.frame.size.width, 100)];
  gradientimageview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  gradientimageview.contentMode = UIViewContentModeScaleAspectFill;
  gradientimageview.clipsToBounds = YES;
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(gradientimageview.frame.size.width, gradientimageview.frame.size.height), NO, gradientimageview.image.scale);
  CAGradientLayer *gradient = [CAGradientLayer layer];
  UIColor *startColor = [UIColor colorWithWhite:0 alpha:0];
  UIColor *endColor = [UIColor colorWithWhite:0 alpha:0.6];
  gradient.frame = CGRectMake(0, 0, gradientimageview.frame.size.width, gradientimageview.frame.size.height);
  gradient.colors = @[(id)startColor.CGColor,(id)endColor.CGColor];
  gradient.startPoint = CGPointMake(0.0f, 1.0f);
  gradient.endPoint = CGPointMake(1.0f, 1.0f);
  [gradientimageview.layer insertSublayer:gradient atIndex:0];
  [gradientimageview.layer renderInContext:UIGraphicsGetCurrentContext()];
  gradientimageview.image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  [gradient removeFromSuperlayer];
  [navigationbar addSubview:gradientimageview];
  [gradientimageview release];
  
  UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, nav.navigationBar.frame.size.width-20, 80)];
  label.tag = 1002;
  label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  //label.font = [UIFont boldSystemFontOfSize:22];
  label.font = [UIFont fontWithName:@"Helvetica-Bold" size:24];
  label.textColor = [UIColor whiteColor];
  label.textAlignment = NSTextAlignmentRight;
  label.numberOfLines = 2;
  [navigationbar addSubview:label];
  [label release];
  
  [nav.view insertSubview:navigationbar atIndex:[nav.view.subviews count]-1];
  [navigationbar release];
  
  self.viewController = nav;
  [nav release];
  [romBrowser release];

  self.window.rootViewController = self.viewController;
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
