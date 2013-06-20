//
//  CUIButton.m
//  YongoPal
//
//  Created by Jiho Kang on 6/30/11.
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

#import "CUIButton.h"

@implementation CUIButton
@synthesize backgroundStates;
@synthesize hitErrorMargin;
@synthesize tempStore;

- (void)setBackgroundColor:(UIColor *)_backgroundColor forState:(UIControlState)_state
{
    if(self.backgroundStates == nil) self.backgroundStates = [[[NSMutableDictionary alloc] init] autorelease];
    [self.backgroundStates setObject:_backgroundColor forKey:[NSNumber numberWithInt:_state]];

    if (self.backgroundColor == nil)
    {
        [self setBackgroundColor:_backgroundColor];
    }
}

- (UIColor*)backgroundColorForState:(UIControlState)_state
{
    return [self.backgroundStates objectForKey:[NSNumber numberWithInt:_state]];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if(hitErrorMargin == 0) hitErrorMargin = 30;
    CGRect largerFrame = CGRectMake(0 - hitErrorMargin, 0 - hitErrorMargin, self.frame.size.width + (hitErrorMargin * 2), self.frame.size.height + (hitErrorMargin * 2));

    return (CGRectContainsPoint(largerFrame, point) == 1) ? self : nil;
}

#pragma mark -
#pragma mark Touches

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
    
    UIColor *selectedColor = [self.backgroundStates objectForKey:[NSNumber numberWithInt:UIControlStateHighlighted]];
    if (selectedColor)
    {
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionFade];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [self.layer addAnimation:animation forKey:@"EaseOut"];
        self.backgroundColor = selectedColor;
    }
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	
    UIColor *normalColor = [self.backgroundStates objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
    if (normalColor)
    {
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionFade];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [self.layer addAnimation:animation forKey:@"EaseOut"];
        self.backgroundColor = normalColor;
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    UIColor *normalColor = [self.backgroundStates objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
    if (normalColor)
    {
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionFade];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [self.layer addAnimation:animation forKey:@"EaseOut"];
        self.backgroundColor = normalColor;
    }
}

- (void) dealloc
{
    self.backgroundStates = nil;
    self.tempStore = nil;
    [super dealloc];
}

@end