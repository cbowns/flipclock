//
//  MFCAppDelegate.h
//  FlipClockDemo
//
//  Created by Christopher Bowns on 6/22/12.
//  Copyright (c) 2012 Mechanical Pants Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MFCViewController;

@interface MFCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) MFCViewController *viewController;

@end
