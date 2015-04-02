//
//  HTInfiniteClipView.m
//  Infinite-NSScrollView
//
//  Created by Milen Dzhumerov on 31/03/2015.
//  Copyright (c) 2015 Helftone. All rights reserved.
//

#import "HTInfiniteClipView.h"
#import "HTInfiniteDocumentView.h"

@interface HTInfiniteClipView ()
@property(readwrite, assign, nonatomic) BOOL inRecenter;
@property(readwrite, assign, nonatomic) BOOL recenterScheduled;
@end

@implementation HTInfiniteClipView

-(void)internal_initInfiniteClipView {
	[self setPostsBoundsChangedNotifications:YES];
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(internal_viewGeometryChanged:) name:NSViewBoundsDidChangeNotification object:self];
	[center addObserver:self selector:@selector(internal_viewGeometryChanged:) name:NSViewFrameDidChangeNotification object:self];
}

-(instancetype)initWithCoder:(NSCoder*)decoder_in {
	if((self = [super initWithCoder:decoder_in])) {
		[self internal_initInfiniteClipView];
	}
	
	return self;
}

-(instancetype)initWithFrame:(NSRect)frameRect_in {
	if((self = [super initWithFrame:frameRect_in])) {
		[self internal_initInfiniteClipView];
	}
	
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Notifications

-(void)internal_viewGeometryChanged:(NSNotification*)note_in {
	CGPoint recenterOffset = [self internal_clipRecenterOffset];
	if(!CGPointEqualToPoint(recenterOffset, CGPointZero)) {
		// We cannot perform recentering from within the notification (it's synchrounous) due to a bug
		// in NSScrollView ... *sigh*
		[self internal_scheduleRecenter];
	}
	
	HTInfiniteDocumentView* docView = [self documentView];
	[docView layoutDocumentView];
}

#pragma mark - Recenter

//      ┌────────────────────────────────────────────────┐
//      │Document View                                   │
//      │                                                │
//      │                                                │
//      │                                                │
//      │                                                │
//      │                                                │
//      │                                                │
//      │                                                │
//      │                                                │
//      │                                                │
//      │    ┌────────────────┐                          │
//      │    │                │                          │
//      │◁──▷│   Clip View    │                          │
//      │    │                │                          │
//      │    └────────────────┘                          │
//      │             △                                  │
//      │             │                                  │
//      │             ▽                                  │
//      └────────────────────────────────────────────────┘
//    (0,0)
//
//                  Recenter Offset: (200,100)
//
//                              │
//                              │
//                              │
//                              │
//                              ▼
//
//
//      ┌────────────────────────────────────────────────┐
//      │Document View                                   │
//      │                                                │
//      │                                                │
//      │                                                │
//      │                                                │
//      │                                                │
//      │               ┌────────────────┐               │
//      │               │                │               │
//      │◁─────────────▷│   Clip View    │               │
//      │               │                │               │
//      │               └────────────────┘               │
//      │                        △                       │
//      │                        │                       │
//      │                        │                       │
//      │          ●             │                       │
//      │        (0,0)           │                       │
//      │                        │                       │
//      │                        ▽                       │
//      └────────────────────────────────────────────────┘
// (-200,-100)
//
// Created with Monodraw
//

// A recenter is performed whenever the clip view gets close to the edge, so that we avoid bouncing
// and breaking the illusion of an infinite scroll view.
-(void)recenterClipView {
	CGPoint clipRecenterOffset = [self internal_clipRecenterOffset];
	if(!CGPointEqualToPoint(clipRecenterOffset, CGPointZero)) {
		_inRecenter = YES;
		
		// We need to add the negative clip offset to the doc view so that the content move in the right direction.
		CGRect recenterDocBounds = [self.documentView bounds];
		recenterDocBounds.origin.x -= clipRecenterOffset.x, recenterDocBounds.origin.y -= clipRecenterOffset.y;
		[self.documentView setBoundsOrigin:recenterDocBounds.origin];
		
		const CGRect clipBounds = [self bounds];
		CGPoint recenterClipOrigin = clipBounds.origin;
		recenterClipOrigin.x += clipRecenterOffset.x, recenterClipOrigin.y += clipRecenterOffset.y;
		[self setBoundsOrigin:recenterClipOrigin];
		
		_inRecenter = NO;
		
#ifdef DEBUG
		NSLog(@"Did recenter infinite clip view: %@", self);
#endif
	}
}

//           ┌──────────────────────────────────────────────────────────────────────────────────┐
//           │Document View                            △                                        │
//           │                                                                                  │
//           │                                         │                                        │
//           │                                                                                  │
//           │                                         │                                        │
//           │                                           maxVerticalDistance                    │
//           │                                         │                                        │
//           │                                                                                  │
//           │                                         │                                        │
//     ▲     │                                         ▽                                        │
//     │     │                             ┌──────────────────────┐                             │
//     │     │                             │                      │                             │
//     │     │    minHorizontalDistance    │                      │    maxHorizontalDistance    │
//     │     │◁ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ▷│      Clip View       │◁ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ▷│
//     │     │                             │                      │                             │
//     │     │                             │                      │                             │
//     │     │                             └──────────────────────┘                             │
//     │     │                                         △                                        │
//     │     │                                                                                  │
//     │     │                                         │                                        │
//     │     │                                                                                  │
//     │     │                                         │ minVerticalDistance                    │
//     │     │                                                                                  │
//     │     │                                         │                                        │
//     │     │                                                                                  │
//     │     │                                         │                                        │
//     │     │                                         ▽                                        │
//     │     └──────────────────────────────────────────────────────────────────────────────────┘
//     │
//     │
// X───┼─────────────────────────────────────▶
//     │
//     Y
//
// Created with Monodraw
//

-(CGPoint)internal_clipRecenterOffset {
	// The threshold needs to be larger than the maximum single scroll distance (otherwise the scroll
	// edge will be hit). Through experimentation, all values stayed below 500.0.
	static const CGFloat HTRecenterThreshold = 500.0;
	
	NSView* docView = [self documentView];
	const CGRect docFrame = [docView frame], clipBounds = [self bounds];
	
	// Compute the distances to the edges, if any of these values gets less than or equal to zero,
	// then the scroll view edge has been hit and the recenter threshold has to be increased.
	const CGFloat minHorizontalDistance = CGRectGetMinX(clipBounds) - CGRectGetMinX(docFrame);
	const CGFloat maxHorizontalDistance = CGRectGetMaxX(docFrame) - CGRectGetMaxX(clipBounds);
	const CGFloat minVerticalDistance = CGRectGetMinY(clipBounds) - CGRectGetMinY(docFrame);
	const CGFloat maxVerticalDistance = CGRectGetMaxY(docFrame) - CGRectGetMaxY(clipBounds);
	if(minHorizontalDistance < HTRecenterThreshold ||
		 maxHorizontalDistance < HTRecenterThreshold ||
		 minVerticalDistance < HTRecenterThreshold   ||
		 maxVerticalDistance < HTRecenterThreshold)
	{
		// Compute desired clip origin and then just return the offset from current origin.
		CGPoint recenterClipOrigin = CGPointZero;
		recenterClipOrigin.x = CGRectGetMinX(docFrame) + round((CGRectGetWidth(docFrame) - CGRectGetWidth(clipBounds)) / 2.0);
		recenterClipOrigin.y = CGRectGetMinY(docFrame) + round((CGRectGetHeight(docFrame) - CGRectGetHeight(clipBounds)) / 2.0);
		return CGPointMake(recenterClipOrigin.x - clipBounds.origin.x, recenterClipOrigin.y - clipBounds.origin.y);
	}
	
	return CGPointZero;
}


-(void)internal_scheduleRecenter {
	if(self.recenterScheduled || self.inRecenter) {
		return;
	}
	
	self.recenterScheduled = YES;
	__typeof__(self) __weak weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		// __typeof__(self) is evaluated at compile time and will _not_ result in retaining self
		__typeof__(self) strongSelf = weakSelf;
		if(strongSelf != nil) {
			strongSelf.recenterScheduled = NO;
			[strongSelf recenterClipView];
		}
	});
}

-(void)scrollToPoint:(NSPoint)newOrigin_in {
	// NSScrollView implements smooth scrolling _only_ for mouse wheel event. This happens inside -scrollToPoint:
	// which will cache the call and subsequently update the bounds. Unfortunately, if we recenter while
	// in a smooth scroll, the scroll view will keep scrolling but will not take into account the recenter.
	// Smooth scrolling can be disabled for an app using NSScrollAnimationEnabled.
	//
	// In order to workaround the issue, we just bypass smooth scrolling and directly scroll.
	//
	// NB: we cannot recenter from here, nsscrollview screws it up if we use a trackpad
	
	[self setBoundsOrigin:newOrigin_in];
}

@end
