//
//  TouchHandle.m
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

#import "TouchHandle.h"
#import "UtilityClasses.h"


@implementation TouchHandle
@synthesize delegate;
@synthesize moveVertical;
@synthesize moveHorizontal;
@synthesize xLimit;
@synthesize yLimit;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		[self setUserInteractionEnabled:YES];
		[self setBackgroundColor:[UIColor clearColor]];
		self.moveVertical = YES;
		self.moveHorizontal = YES;
		startPoint = CGPointMake(self.frame.origin.x, self.frame.origin.y);
		xLimit = 320;
		yLimit = [UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO];
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
    [super dealloc];
}

- (void)positionHandleTop
{
	CGRect newFrame = CGRectMake(startPoint.x, startPoint.y, self.frame.size.width, self.frame.size.height);
	[self setFrame:newFrame];
}

- (void)positionHandleBottom
{
	CGRect newFrame = CGRectMake(xLimit - self.frame.size.width, yLimit - self.frame.size.height, self.frame.size.width, self.frame.size.height);
	[self setFrame:newFrame];
}

- (void)repositionHandle:(CGPoint)location
{
	float dx = 0;
	if(moveHorizontal == YES)
	{
		dx = location.x - touchPoint.x;
	}
	
	float dy = 0;
	if(moveVertical == YES)
	{
		dy = location.y - touchPoint.y;
	}
	
	float newX = self.frame.origin.x + dx;
	float newY = self.frame.origin.y + dy;

	if(newX >= startPoint.x && newY >= startPoint.y && newX + self.frame.size.width < xLimit && newY + self.frame.size.height < yLimit)
	{
		CGRect newFrame = CGRectMake(newX, newY, self.frame.size.width, self.frame.size.height);
		[self setFrame:newFrame];
	}
	else
	{
		if(newX < startPoint.x) newX = startPoint.x;
		else if(newX + self.frame.size.width >= xLimit) newX = xLimit - self.frame.size.width;
		
		if(newY < startPoint.y) newY = startPoint.y;
		else if(newY + self.frame.size.height >= yLimit) newY = yLimit - self.frame.size.height;
		
		CGRect newFrame = CGRectMake(newX, newY, self.frame.size.width, self.frame.size.height);
		[self setFrame:newFrame];
	}
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	// Calculate and store offset, and pop view into front if needed
	CGPoint pt = [[touches anyObject] locationInView:self];
	[delegate touchBegan:pt];

	touchPoint = pt;
	[[self superview] bringSubviewToFront:self];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	// Calculate offset
	CGPoint pt = [[touches anyObject] locationInView:self];
	[delegate touchMoved:pt];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint pt = [[touches anyObject] locationInView:self];
	[delegate touchMoved:pt];
	[self repositionHandle:pt];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint pt = [[touches anyObject] locationInView:self];
	[self repositionHandle:pt];
	[delegate touchesEnded:pt];
}

@end
