//
//  HTContentView.m
//  Infinite-NSScrollView
//
//  Created by Milen Dzhumerov on 31/03/2015.
//  Copyright (c) 2015 Helftone. All rights reserved.
//

#import "HTContentTileView.h"

@implementation HTContentTileView

-(BOOL)wantsUpdateLayer {
	return YES;
}

-(void)updateLayer {
	CALayer* layer = [self layer];
	[layer setBackgroundColor:[self.backgroundColor CGColor]];
}

-(void)setBackgroundColor:(NSColor*)backgroundColor_in {
	if(_backgroundColor != backgroundColor_in) {
		_backgroundColor = backgroundColor_in;
		[self setNeedsDisplay:YES];
	}
}

@end
