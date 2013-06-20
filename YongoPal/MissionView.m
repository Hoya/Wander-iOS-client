//
//  MissionView.m
//  YongoPal
//
//  Created by Jiho Kang on 6/27/11.
//  Copyright 2011 BetaStudios, Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MissionView.h"


@implementation MissionView
@synthesize scrollView;
@synthesize pageController;
@synthesize handle;
@synthesize yLimit;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		startHeight = self.frame.size.height;

        // Initialization code
		scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 70)];
		[scrollView setPagingEnabled:YES];
		[scrollView setShowsHorizontalScrollIndicator:NO];
		[scrollView setShowsVerticalScrollIndicator:NO];
		[scrollView setBounces:YES];
		[self addSubview:self.scrollView];
		
		pageController = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 70, 320, 36)];
		[self addSubview:self.pageController];
		
		handle = [[TouchHandle alloc] initWithFrame:CGRectMake(0, 70, 320, 50)];
		[handle setMoveVertical:YES];
		[handle setMoveHorizontal:NO];
		[handle setDelegate:self];
		[handle setBackgroundColor:[UIColor redColor]];
		[self addSubview:handle];

		[self setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    self.scrollView = nil;
    self.pageController = nil;
    self.handle = nil;
    
	[scrollView release];
	[pageController release];
	[handle release];

    [super dealloc];
}

- (void)touchBegan:(CGPoint)location
{
	[handle setYLimit:yLimit];
	startLocation = location;
	currentHeight = self.frame.size.height;
}

- (void)touchMoved:(CGPoint)location
{
	// Calculate offset
	CGPoint pt = location;
	
	float dy = pt.y - startLocation.y;
	float newHeight = currentHeight + dy;

	if(newHeight > startHeight && newHeight < yLimit)
	{
		[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, newHeight)];
		[scrollView setFrame:CGRectMake(0, 0, self.frame.size.width, newHeight - 50)];
		[pageController setFrame:CGRectMake(0, newHeight - 36 - 14, 320, 36)];
	}
	else if(newHeight > yLimit)
	{
		[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, yLimit)];
		[scrollView setFrame:CGRectMake(0, 0, self.frame.size.width, yLimit - 50)];
		[pageController setFrame:CGRectMake(0, yLimit - 36 - 14, 320, 36)];
	}
	else if(newHeight < startHeight)
	{
		[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, startHeight)];
		[scrollView setFrame:CGRectMake(0, 0, self.frame.size.width, startHeight - 50)];
		[pageController setFrame:CGRectMake(0, startHeight - 36 - 14, 320, 36)];
	}
}

- (void)touchesEnded:(CGPoint)location
{
	float dy = location.y - startLocation.y;
	float newHeight = currentHeight + dy;
	
	if(newHeight > startHeight && newHeight < yLimit)
	{
		if((currentHeight == startHeight && newHeight < startHeight + 50) || (currentHeight == yLimit && newHeight < yLimit - 50))
		{
			[UIView beginAnimations:@"snapMissionView" context:nil];
			[UIView setAnimationDuration:0.2];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];

			[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, startHeight)];
			[scrollView setFrame:CGRectMake(0, 0, self.frame.size.width, startHeight - 50)];
			[pageController setFrame:CGRectMake(0, startHeight - 36 - 14, 320, 36)];

			[UIView commitAnimations];

			[handle positionHandleTop];
		}
		else if((currentHeight == startHeight && newHeight > startHeight + 50) || (currentHeight == yLimit && newHeight > yLimit - 50))
		{
			[UIView beginAnimations:@"snapMissionView" context:nil];
			[UIView setAnimationDuration:0.2];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];

			[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, yLimit)];
			[scrollView setFrame:CGRectMake(0, 0, self.frame.size.width, yLimit - 50)];
			[pageController setFrame:CGRectMake(0, yLimit - 36 - 14, 320, 36)];
			
			[UIView commitAnimations];
			
			[handle positionHandleBottom];
		}
	}
	else if(newHeight > yLimit)
	{
		[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, yLimit)];
		[scrollView setFrame:CGRectMake(0, 0, self.frame.size.width, yLimit - 50)];
		[pageController setFrame:CGRectMake(0, yLimit - 36 - 14, 320, 36)];
	}
	else if(newHeight < startHeight)
	{
		[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, startHeight)];
		[scrollView setFrame:CGRectMake(0, 0, self.frame.size.width, startHeight - 50)];
		[pageController setFrame:CGRectMake(0, startHeight - 36 - 14, 320, 36)];
	}
}

@end
