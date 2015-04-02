//
//  AppDelegate.m
//  Infinite-NSScrollView
//
//  Created by Milen Dzhumerov on 31/03/2015.
//  Copyright (c) 2015 Helftone. All rights reserved.
//

#import "AppDelegate.h"
#import "HTInfiniteClipView.h"

@interface AppDelegate ()
@property(readwrite, strong, nonatomic) IBOutlet NSWindow* window;
@property(readwrite, strong, nonatomic) IBOutlet NSScrollView* scrollView;
@end

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification*)note_in {
	// Enable layer-backing for the view hierarchy, required by the tile views
	NSView* contentView = [self.window contentView];
	[contentView setWantsLayer:YES];
	
	// The frame size needs to be larger than the sum of largest attached screen + recenter threshold.
	NSView* docView = [self.scrollView documentView];
	[docView setFrameSize:CGSizeMake(4000, 4000)];
	
	// Provide the illusion of an infinite scroll view by hiding all the scrollers.
	[self.scrollView setHasVerticalScroller:NO];
	[self.scrollView setHasHorizontalScroller:NO];
	
	// There's no need for elasticity.
	[self.scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
	[self.scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
	
	// Force an initial recenter so user can scroll in all directions.
	HTInfiniteClipView* infiniteClipView = (HTInfiniteClipView*)[self.scrollView contentView];
	[infiniteClipView recenterClipView];
}

@end
