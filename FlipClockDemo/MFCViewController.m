//
//  MFCViewController.m
//  FlipClockDemo
//
//  Created by Christopher Bowns on 6/22/12.
//  Copyright (c) 2012 Mechanical Pants Software. All rights reserved.
//

#import "MFCViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface MFCViewController ()

@end

@implementation MFCViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	UIView *aNumberView = nil;
	{{
		// Make a label
		UILabel *digitLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		digitLabel.font = [UIFont systemFontOfSize:160.f];
		digitLabel.text = @"1";
		digitLabel.textAlignment = UITextAlignmentCenter;
		digitLabel.textColor = [UIColor whiteColor];
		digitLabel.backgroundColor = [UIColor clearColor];
		[digitLabel sizeToFit];

		// Add the label to a wrapper view for corners.
		aNumberView = [[UIView alloc] initWithFrame:CGRectZero];
		aNumberView.frame = CGRectMake(0.f, 0.f, 100.f, 200.f);
		aNumberView.layer.cornerRadius = 10.f;
		aNumberView.layer.masksToBounds = YES;
		aNumberView.backgroundColor = [UIColor blackColor];

		digitLabel.center = CGPointMake(aNumberView.bounds.size.width / 2, aNumberView.bounds.size.height / 2);
		[aNumberView addSubview:digitLabel];

		// Put a dividing line over the label:
		UIView *lineView = [[UIView alloc] init];
		lineView.backgroundColor = [UIColor blackColor];
		lineView.frame = CGRectMake(0.f, 0.f, aNumberView.frame.size.width, 10.f);
		lineView.center = digitLabel.center;

		[aNumberView addSubview:lineView];
	}}

	// Wrapper view for the view that holds the label, since the label's wrapper does the corners.
	// It'll be easier later to control masksToBounds on another layer.
	UIView *wrapperView = [[UIView alloc] initWithFrame:aNumberView.frame];
	[wrapperView addSubview:aNumberView];

	// Add the top-level view
	wrapperView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
	[self.view addSubview:wrapperView];

	// Add a tap gesture recognizer:
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewWasTapped:)];
	[wrapperView addGestureRecognizer:tapGestureRecognizer];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
}

#pragma mark - UITapGestureRecognizer callbacks

- (void)viewWasTapped:(UITapGestureRecognizer *)tapGestureRecognizer;
{
	NSLog(@"%s %@", __func__, tapGestureRecognizer);
	UIView *aView = tapGestureRecognizer.view;

	// Render the tapped view into an image:
	UIGraphicsBeginImageContextWithOptions(aView.bounds.size, aView.layer.opaque, 0.f);
    [aView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *renderedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

	// The size of each part is half the height of the whole image:
	CGSize size = CGSizeMake(renderedImage.size.width, renderedImage.size.height / 2);

	UIImage *top = nil;
	UIImage *bottom = nil;
	UIGraphicsBeginImageContextWithOptions(size, aView.layer.opaque, 0.f);
	{{
		// Draw into context, bottom half is cropped off
		[renderedImage drawAtPoint:CGPointZero];

		// Grab the current contents of the context as a UIImage 
		// and add it to our array
		top = UIGraphicsGetImageFromCurrentImageContext();
	}}
	UIGraphicsEndImageContext();

	UIGraphicsBeginImageContextWithOptions(size, aView.layer.opaque, 0.f);
	{{
		// Now draw the image starting half way down, to get the bottom half
		[renderedImage drawAtPoint:CGPointMake(CGPointZero.x, -renderedImage.size.height / 2)];

		// And store that image in the array too
		bottom = UIGraphicsGetImageFromCurrentImageContext();
	}}
	UIGraphicsEndImageContext();

	UIImageView *topHalfView = [[UIImageView alloc] initWithImage:top];
	[self.view addSubview:topHalfView];

	UIImageView *bottomHalfView = [[UIImageView alloc] initWithImage:bottom];
	bottomHalfView.frame = CGRectOffset(bottomHalfView.frame, 0.f, topHalfView.frame.size.height);
	[self.view addSubview:bottomHalfView];
}

@end
