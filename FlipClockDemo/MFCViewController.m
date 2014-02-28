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
	NSUInteger viewIndex;
	NSUInteger nextViewIndex;
	NSArray *clockTiles;
	IBOutlet UILabel *speedLabel;
	IBOutlet UISlider *speedSlider;
	IBOutlet UILabel *zLabel;
	IBOutlet UISlider *zSlider;
	CGFloat duration;
	CGFloat zDepth;
}

@end

@implementation MFCViewController

- (id)init;
{
	self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
	if (self) {
		// Custom initialization goes here

		NSMutableArray *newTiles = [NSMutableArray array];
		for (int i = 1; i < 10; i++) {
			UIView *aNewView = [self viewWithText:[NSString stringWithFormat:@"%i", i]];
			[newTiles addObject:aNewView];
		}

		clockTiles = [NSArray arrayWithArray:newTiles];
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	return [self init];
}

- (void)dealloc
{
	clockTiles = nil;
}

// Get a large clock-like view with the given text.
- (UIView *)viewWithText:(NSString *)text;
{
	UIView *aNewView = nil;

	// Make a label
	UILabel *digitLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	digitLabel.font = [UIFont systemFontOfSize:160.f];
	digitLabel.text = text;
	digitLabel.textAlignment = UITextAlignmentCenter;
	digitLabel.textColor = [UIColor whiteColor];
	digitLabel.backgroundColor = [UIColor clearColor];
	[digitLabel sizeToFit];

	// Add the label to a wrapper view for corners.
	aNewView = [[UIView alloc] initWithFrame:CGRectZero];
	aNewView.frame = CGRectMake(0.f, 0.f, 100.f, 200.f);
	aNewView.layer.cornerRadius = 10.f;
	aNewView.layer.masksToBounds = YES;
	aNewView.backgroundColor = [UIColor blackColor];

	digitLabel.center = CGPointMake(aNewView.bounds.size.width / 2, aNewView.bounds.size.height / 2);
	[aNewView addSubview:digitLabel];

	// Put a dividing line over the label:
	UIView *lineView = [[UIView alloc] init];
	lineView.backgroundColor = [UIColor blackColor];
	lineView.frame = CGRectMake(0.f, 0.f, aNewView.frame.size.width, 10.f);
	lineView.center = digitLabel.center;

	[aNewView addSubview:lineView];

	return aNewView;
}

- (void)addSubviewWithTapRecognizer:(UIView *)aNewView;
{
	// Add the views to our view:
	aNewView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
	[self.view addSubview:aNewView];

	// Add a tap gesture recognizer:
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewWasTapped:)];
	[aNewView addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	UIView *aNumberView = [clockTiles objectAtIndex:8];
	[self addSubviewWithTapRecognizer:aNumberView];

	// Update our slider labels:
	[self speedSliderValueDidChange:speedSlider];
	[self zIndexValueDidChange:zSlider];
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
	viewIndex = [clockTiles indexOfObject:tapGestureRecognizer.view];
	NSUInteger tileCount = [clockTiles count];
	nextViewIndex = NSNotFound;
	if (viewIndex == (tileCount - 1)) {
		nextViewIndex = 0;
	} else {
		nextViewIndex = viewIndex + 1;
	}

	[self changeAnimationState];
}

- (NSArray *)snapshotsForView:(UIView *)aView;
{
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

	NSArray *views = @[topHalfView, bottomHalfView];
	for (UIView *view in views) {
		[self setEdgeAntialiasingOn:view.layer];
	}

	return views;
}

/// Helper for enabling edge antialiasing on 7.0+.
- (void)setEdgeAntialiasingOn:(CALayer *)layer
{
	// Only test this selector once.
	static BOOL deviceTested = NO;
	static BOOL deviceSupportsAntialiasing = NO;
	if (!deviceTested) {
		deviceTested = YES;
		deviceSupportsAntialiasing = [CALayer instancesRespondToSelector:@selector(setAllowsEdgeAntialiasing:)];
	}

	// Turn on edge antialiasing.
	if (deviceSupportsAntialiasing) {
		layer.allowsEdgeAntialiasing = YES;
	}
}

- (void)animateViewDown:(UIView *)aView withNextView:(UIView *)nextView withDuration:(CGFloat)aDuration;
{
	// Get snapshots for the first view:
	NSArray *frontViews = [self snapshotsForView:aView];
	topHalfFrontView = [frontViews firstObject];
	bottomHalfFrontView = [frontViews lastObject];

	// Move this view to be where the original view is:
	topHalfFrontView.frame = CGRectOffset(topHalfFrontView.frame, aView.frame.origin.x, aView.frame.origin.y);
	[self.view addSubview:topHalfFrontView];

	// Move the bottom half into place:
	bottomHalfFrontView.frame = topHalfFrontView.frame;
	bottomHalfFrontView.frame = CGRectOffset(bottomHalfFrontView.frame, 0.f, topHalfFrontView.frame.size.height);
	[self.view addSubview:bottomHalfFrontView];
	// And get rid of the original view:
	[aView removeFromSuperview];

	// Get snapshots for the second view:
	NSArray *backViews = [self snapshotsForView:nextView];
	topHalfBackView = [backViews firstObject];
	bottomHalfBackView = [backViews lastObject];
	topHalfBackView.frame = topHalfFrontView.frame;
	// And place them in the view hierarchy:
	[self.view insertSubview:topHalfBackView belowSubview:topHalfFrontView];
	bottomHalfBackView.frame = bottomHalfFrontView.frame;
	[self.view insertSubview:bottomHalfBackView belowSubview:bottomHalfFrontView];


	////////////////
	// Animations //
	////////////////

	// Skewed identity for camera perspective:
	CATransform3D skewedIdentityTransform = CATransform3DIdentity;
	float zDistance = zDepth;
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
	topAnim.duration = aDuration;
	topAnim.fromValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
	topAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, -M_PI_2, 1.f, 0.f, 0.f)];
	topAnim.delegate = self;
	topAnim.removedOnCompletion = NO;
	topAnim.fillMode = kCAFillModeForwards;
	topAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
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
	bottomAnim.duration = topAnim.duration / 3;
	bottomAnim.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, M_PI_2, 1.f, 0.f, 0.f)];
	bottomAnim.toValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
	bottomAnim.delegate = self;
	bottomAnim.removedOnCompletion = NO;
	bottomAnim.fillMode = kCAFillModeBoth;
	bottomAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	[bottomHalfBackView.layer addAnimation:bottomAnim forKey:@"bottomDownFlip"];
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
		{{
			UIView *aView = [clockTiles objectAtIndex:viewIndex];
			UIView *nextView = [clockTiles objectAtIndex:nextViewIndex];
			[self animateViewDown:aView withNextView:nextView withDuration:duration];

			NSLog(@"moving to state kFlipAnimationTopDown");
			animationState = kFlipAnimationTopDown;
		}}
			break;
		case kFlipAnimationTopDown:
			// Swap some tiles around:
			[bottomHalfBackView.superview bringSubviewToFront:bottomHalfBackView];

			NSLog(@"moving to state kFlipAnimationBottomDown");
			animationState = kFlipAnimationBottomDown;
			break;
		case kFlipAnimationBottomDown:
		{{
			UIView *newView = [clockTiles objectAtIndex:nextViewIndex];
			[self addSubviewWithTapRecognizer:newView];

			// Remove snapshots:
			[topHalfFrontView removeFromSuperview];
			[bottomHalfFrontView removeFromSuperview];
			[topHalfBackView removeFromSuperview];
			[bottomHalfBackView removeFromSuperview];
			topHalfFrontView = bottomHalfFrontView = topHalfBackView = bottomHalfBackView = nil;

			// And reset other state:
			nextViewIndex = viewIndex = NSNotFound;

			NSLog(@"moving to state kFlipAnimationNormal");
			animationState = kFlipAnimationNormal;
		}}
			break;
	}
}

#pragma mark - UISlider Event Handling

- (IBAction)speedSliderValueDidChange:(id)sender;
{
	NSLog(@"%s %@", __func__, sender);
	UISlider *aSlider = (UISlider *)sender;
	duration = aSlider.value;
	speedLabel.text = [NSString stringWithFormat:@"%.2f s", duration];
}

- (IBAction)zIndexValueDidChange:(id)sender;
{
	NSLog(@"%s %@", __func__, sender);
	UISlider *aSlider = (UISlider *)sender;
	zDepth = aSlider.value;
	zLabel.text = [NSString stringWithFormat:@"%.0f", zDepth];
}

@end
