//
//  MFCViewController.m
//  FlipClockDemo
//
//  Created by Christopher Bowns on 6/22/12.
//  Copyright (c) 2012 Mechanical Pants Software. All rights reserved.
//

#import "MFCViewController.h"
#import <QuartzCore/QuartzCore.h>

typedef enum {
	kFlipAnimationNormal = 0,
	kFlipAnimationTopDown,
	kFlipAnimationBottomDown
} kFlipAnimationState;

@interface MFCViewController () {
	kFlipAnimationState animationState;
	UIView *topHalfFrontView;
	UIView *bottomHalfFrontView;
	UIView *topHalfBackView;
	UIView *bottomHalfBackView;
}

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

	UIView *secondNumberView = nil;
	{{
		// Make a label
		UILabel *digitLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		digitLabel.font = [UIFont systemFontOfSize:160.f];
		digitLabel.text = @"2";
		digitLabel.textAlignment = UITextAlignmentCenter;
		digitLabel.textColor = [UIColor whiteColor];
		digitLabel.backgroundColor = [UIColor clearColor];
		[digitLabel sizeToFit];

		// Add the label to a wrapper view for corners.
		secondNumberView = [[UIView alloc] initWithFrame:CGRectZero];
		secondNumberView.frame = CGRectMake(0.f, 0.f, 100.f, 200.f);
		secondNumberView.layer.cornerRadius = 10.f;
		secondNumberView.layer.masksToBounds = YES;
		secondNumberView.backgroundColor = [UIColor blackColor];
		
		digitLabel.center = CGPointMake(secondNumberView.bounds.size.width / 2, secondNumberView.bounds.size.height / 2);
		[secondNumberView addSubview:digitLabel];
		
		// Put a dividing line over the label:
		UIView *lineView = [[UIView alloc] init];
		lineView.backgroundColor = [UIColor blackColor];
		lineView.frame = CGRectMake(0.f, 0.f, secondNumberView.frame.size.width, 10.f);
		lineView.center = digitLabel.center;
		
		[secondNumberView addSubview:lineView];
	}}

	// Wrapper view for the view that holds the label, since the label's wrapper does the corners.
	// It'll be easier later to control masksToBounds on another layer.
	UIView *wrapperView = [[UIView alloc] initWithFrame:aNumberView.frame];
	[wrapperView addSubview:aNumberView];

	UIView *secondWrapperView = [[UIView alloc] initWithFrame:secondNumberView.frame];
	[secondWrapperView addSubview:secondNumberView];

	// Add the top-level view
	wrapperView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
	[self.view addSubview:wrapperView];
	secondWrapperView.center = wrapperView.center;
	[self.view insertSubview:secondWrapperView belowSubview:wrapperView];

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
	animationState = kFlipAnimationNormal;
	[self changeAnimationState];
	NSArray *subviews = [[tapGestureRecognizer.view superview] subviews];
	NSUInteger subviewOffset = [subviews indexOfObject:tapGestureRecognizer.view];
	UIView *nextView = [subviews objectAtIndex:subviewOffset - 1];
	[self animateViewDown:tapGestureRecognizer.view withNextView:nextView];
}

- (NSArray *)snapshotsForView:(UIView *)aView;
{
	NSArray *returnArray = nil;

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
	UIImageView *bottomHalfView = [[UIImageView alloc] initWithImage:bottom];

	returnArray = [NSArray arrayWithObjects:topHalfView, bottomHalfView, nil];
	return returnArray;
}

- (void)animateViewDown:(UIView *)aView withNextView:(UIView *)nextView;
{
	// Get snapshots for the first view:
	NSArray *frontViews = [self snapshotsForView:aView];
	topHalfFrontView = [frontViews objectAtIndex:0];
	bottomHalfFrontView = [frontViews objectAtIndex:1];

	topHalfFrontView.frame = CGRectOffset(topHalfFrontView.frame, 20.f, 0.f);
	[self.view addSubview:topHalfFrontView];

	bottomHalfFrontView.frame = topHalfFrontView.frame;
	bottomHalfFrontView.frame = CGRectOffset(bottomHalfFrontView.frame, 0.f, topHalfFrontView.frame.size.height);
	[self.view addSubview:bottomHalfFrontView];

	// Get snapshots for the second view:
	NSArray *backViews = [self snapshotsForView:nextView];
	topHalfBackView = [backViews objectAtIndex:0];
	bottomHalfBackView = [backViews objectAtIndex:1];
	topHalfBackView.frame = topHalfFrontView.frame;
	[self.view insertSubview:topHalfBackView belowSubview:topHalfFrontView];

	bottomHalfBackView.frame = bottomHalfFrontView.frame;
	[self.view insertSubview:bottomHalfBackView belowSubview:bottomHalfFrontView];
	
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
	CGPoint newTopViewCenter = [self center:topHalfFrontView.center movedFromAnchorPoint:topHalfFrontView.layer.anchorPoint toAnchorPoint:newTopViewAnchorPoint withFrame:topHalfFrontView.frame];
	topHalfFrontView.layer.anchorPoint = newTopViewAnchorPoint;
	topHalfFrontView.center = newTopViewCenter;

	// Add an animation to swing from top to bottom.
	CABasicAnimation *topAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
	topAnim.beginTime = CACurrentMediaTime();
	topAnim.duration = 1.0f;
	topAnim.fromValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
	topAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, -M_PI_2, 1.f, 0.f, 0.f)];
	topAnim.delegate = self;
	topAnim.removedOnCompletion = NO;
	topAnim.fillMode = kCAFillModeForwards;
	[topHalfFrontView.layer addAnimation:topAnim forKey:@"topDownFlip"];

	// Bottom tile:
	// Change its anchor point:
	CGPoint newAnchorPointBottomHalf = CGPointMake(0.5f, 0.f);
	CGPoint newBottomHalfCenter = [self center:bottomHalfBackView.center movedFromAnchorPoint:bottomHalfBackView.layer.anchorPoint toAnchorPoint:newAnchorPointBottomHalf withFrame:bottomHalfBackView.frame];
	bottomHalfBackView.layer.anchorPoint = newAnchorPointBottomHalf;
	bottomHalfBackView.center = newBottomHalfCenter;

	// Add an animation to swing from top to bottom.
	CABasicAnimation *bottomAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
	bottomAnim.beginTime = topAnim.beginTime + topAnim.duration;
	bottomAnim.duration = topAnim.duration;
	bottomAnim.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, M_PI_2, 1.f, 0.f, 0.f)];
	bottomAnim.toValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
	bottomAnim.delegate = self;
	bottomAnim.removedOnCompletion = NO;
	bottomAnim.fillMode = kCAFillModeBoth;
	[bottomHalfBackView.layer addAnimation:bottomAnim forKey:@"topDownFlip"];
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

#pragma mark - CAAnimation delegate callbacks

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag;
{
	NSLog(@"%s", __func__);
	[self changeAnimationState];
}

- (void)changeAnimationState;
{
	switch (animationState) {
		case kFlipAnimationNormal:
			// Snapshot the view, animate it down.
			NSLog(@"moving to state kFlipAnimationTopDown");
			animationState = kFlipAnimationTopDown;
			break;
		case kFlipAnimationTopDown:
			// Swap animations.
			NSLog(@"moving to state kFlipAnimationBottomDown");
			animationState = kFlipAnimationBottomDown;
			[bottomHalfFrontView removeFromSuperview];
			[bottomHalfBackView.superview addSubview:bottomHalfFrontView];
			break;
		case kFlipAnimationBottomDown:
			// Clean up.
			NSLog(@"moving to state kFlipAnimationNormal");
			animationState = kFlipAnimationNormal;
			break;
	}
}

@end
