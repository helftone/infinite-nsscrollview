//
//  HTInfiniteDocumentView.m
//  Infinite-NSScrollView
//
//  Created by Milen Dzhumerov on 31/03/2015.
//  Copyright (c) 2015 Helftone. All rights reserved.
//

#import "HTInfiniteDocumentView.h"
#import "HTContentTileView.h"

typedef struct {
	NSInteger x, y;
} HTTileKey;

@interface HTInfiniteDocumentView ()
@property(readwrite, strong, nonatomic) NSMutableDictionary* tileViewMap;
@end

@implementation HTInfiniteDocumentView

-(void)internal_initInfiniteDocumentView {
	self.tileViewMap = [NSMutableDictionary dictionary];
	[self layoutDocumentView];
}

-(instancetype)initWithFrame:(NSRect)frameRect_in {
	if((self = [super initWithFrame:frameRect_in])) {
		[self internal_initInfiniteDocumentView];
	}
	
	return self;
}

-(instancetype)initWithCoder:(NSCoder*)coder_in {
	if((self = [super initWithCoder:coder_in])) {
		[self internal_initInfiniteDocumentView];
	}
	
	return self;
}

// This method should be called whenever the visible rect changes. This can be done synchronously
// (e.g., on bounds change) or asynchronously (e.g., async dispatch) or any other way.
-(void)layoutDocumentView {
	static const CGSize tileSize = {.width = 250.0, .height = 250.0};
	
	const CGRect visibleRect = [self visibleRect];
	
	// min = inclusive; max = exclusive; i.e., [min, max)
	const NSInteger xMinIndex = floor(CGRectGetMinX(visibleRect) / tileSize.width);
	const NSInteger xMaxIndex = ceil(CGRectGetMaxX(visibleRect) / tileSize.width);
	
	const NSInteger yMinIndex = floor(CGRectGetMinY(visibleRect) / tileSize.height);
	const NSInteger yMaxIndex = ceil(CGRectGetMaxY(visibleRect) / tileSize.height);
	
	for(NSInteger x = xMinIndex; x < xMaxIndex; ++x) {
		for(NSInteger y = yMinIndex; y < yMaxIndex; ++y) {
			if(ABS(x + y) % 2 != 0) {
				// skip every other tile and alternate between rows
				continue;
			}
			
			const HTTileKey tileKey = (HTTileKey){.x = x, .y = y};
			NSValue* tileKeyBoxed = [NSValue valueWithBytes:&tileKey objCType:@encode(HTTileKey)];
			if(self.tileViewMap[tileKeyBoxed] == nil) {
				const CGRect tileFrame = (CGRect){.origin = CGPointMake(x * tileSize.width, y * tileSize.height), .size = tileSize};
				const CGRect viewFrame = CGRectInset(tileFrame, 50, 50);
				HTContentTileView* tileView = [[HTContentTileView alloc] initWithFrame:viewFrame];
				tileView.backgroundColor = x % 2 == 0 ? [NSColor blackColor] : [NSColor blueColor];
				[self addSubview:tileView];
				
				self.tileViewMap[tileKeyBoxed] = tileView;
			}
		}
	}
	
	// remove offscreen views
	for(NSValue* tileKeyBoxed in [self.tileViewMap allKeys]) {
		HTTileKey tileKey = {};
		[tileKeyBoxed getValue:&tileKey];
		
		if(!(xMinIndex <= tileKey.x && tileKey.x < xMaxIndex && yMinIndex <= tileKey.y && tileKey.y < yMaxIndex)) {
			NSView* tileView = self.tileViewMap[tileKeyBoxed];
			[self.tileViewMap removeObjectForKey:tileKeyBoxed];
			[tileView removeFromSuperview];
		}
	}
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize_in {
	[self layoutDocumentView];
}

@end
