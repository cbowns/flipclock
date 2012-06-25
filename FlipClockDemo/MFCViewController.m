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

	///////////////////////
	// View snapshotting //
	///////////////////////

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
	topHalfView.frame = CGRectOffset(topHalfView.frame, 20.f, 0.f); // move in 20 px
	[self.view addSubview:topHalfView];

	UIImageView *bottomHalfView = [[UIImageView alloc] initWithImage:bottom];
	bottomHalfView.frame = topHalfView.frame;
	bottomHalfView.frame = CGRectOffset(bottomHalfView.frame, 20.f, topHalfView.frame.size.height * 3); // temp move in 20 px
	[self.view addSubview:bottomHalfView];



	////////////////
	// Animations //
	////////////////

	// Skewed identity for camera perspective:
	CATransform3D skewedIdentityTransform = CATransform3DIdentity;
	float zDistance = 1000;
	skewedIdentityTransform.m34 = 1.0 / -zDistance;
	// We use this instead of setting a sublayer transform on our view's layer,
	// because that gives an undesirable skew on views not centered horizontally.

	// Top tile:
	// Set the anchor point to the bottom edge:
	CGPoint newTopViewAnchorPoint = CGPointMake(0.5, 1.0);
	CGPoint newTopViewCenter = [self center:topHalfView.center movedFromAnchorPoint:topHalfView.layer.anchorPoint toAnchorPoint:newTopViewAnchorPoint withFrame:topHalfView.frame];
	topHalfView.layer.anchorPoint = newTopViewAnchorPoint;
	topHalfView.center = newTopViewCenter;

	// Add an animation to swing from top to bottom.
	CABasicAnimation *topAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
	topAnim.beginTime = CACurrentMediaTime();
	topAnim.duration = 2.5f;
	topAnim.fromValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
	topAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, -M_PI, 1.f, 0.f, 0.f)];
	topAnim.delegate = self;
	topAnim.removedOnCompletion = NO;
	topAnim.fillMode = kCAFillModeForwards;
	[topHalfView.layer addAnimation:topAnim forKey:@"topDownFlip"];

	// Bottom tile:
	// Change its anchor point:
	CGPoint newAnchorPointBottomHalf = CGPointMake(0.5f, 0.f);
	CGPoint newBottomHalfCenter = [self center:bottomHalfView.center movedFromAnchorPoint:bottomHalfView.layer.anchorPoint toAnchorPoint:newAnchorPointBottomHalf withFrame:bottomHalfView.frame];
	bottomHalfView.layer.anchorPoint = newAnchorPointBottomHalf;
	bottomHalfView.center = newBottomHalfCenter;

	// Add an animation to swing from top to bottom.
	CABasicAnimation *bottomAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
	bottomAnim.beginTime = topAnim.beginTime + topAnim.duration;
	bottomAnim.duration = topAnim.duration;
	bottomAnim.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, M_PI, 1.f, 0.f, 0.f)];
	bottomAnim.toValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
	bottomAnim.delegate = self;
	bottomAnim.removedOnCompletion = NO;
	bottomAnim.fillMode = kCAFillModeBoth;
	[bottomHalfView.layer addAnimation:bottomAnim forKey:@"topDownFlip"];

//	anim2.beginTime = anim1.beginTime + anim1.duration;
//	anim3.beginTime = anim2.beginTime + anim2.duration;

}

// Scales center points by the difference in their anchor points scaled to their frame size.
// Lets you move anchor points around without dealing with CA's implicit frame math.
- (CGPoint)center:(CGPoint)oldCenter movedFromAnchorPoint:(CGPoint)oldAnchorPoint toAnchorPoint:(CGPoint)newAnchorPoint withFrame:(CGRect)frame;
{
	NSLog(@"%s moving center (%.2f, %.2f) from oldAnchor (%.2f, %.2f) to newAnchor (%.2f, %.2f)", __func__,
		  oldCenter.x, oldCenter.y, oldAnchorPoint.x, oldAnchorPoint.y, newAnchorPoint.x, newAnchorPoint.y);
	CGPoint anchorPointDiff = CGPointMake(newAnchorPoint.x - oldAnchorPoint.x, newAnchorPoint.y - oldAnchorPoint.y);
	CGPoint newCenter = CGPointMake(oldCenter.x + (anchorPointDiff.x * frame.size.width), 
									oldCenter.y + (anchorPointDiff.y * frame.size.height));
	NSLog(@"%s new center is (%.2f, %.2f) (frame size: (%.2f, %.2f))", __func__, newCenter.x, newCenter.y, frame.size.width, frame.size.height);
	return newCenter;
}

@end
