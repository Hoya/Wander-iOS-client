//
//  UINavigationBar+CustomBackground.m
//  YongoPal
//
//  Created by Jiho Kang on 4/25/11.
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
 
#import "UINavigationBar+CustomBackground.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIBezierPath.h>
#import <objc/runtime.h>

@implementation UINavigationBar(CustomBackground)

+ (void)load
{
    SEL originalSelector = @selector(layoutSubviews);
    SEL overrideSelector = @selector(customLayoutSubviews);
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method overrideMethod = class_getInstanceMethod(self, overrideSelector);

    if (class_addMethod(self, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod)))
	{
		class_replaceMethod(self, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
	else
	{
		method_exchangeImplementations(originalMethod, overrideMethod);
    }

    SEL originalSelector2 = @selector(drawRect:);
    SEL overrideSelector2 = @selector(customDrawRect:);
    Method originalMethod2 = class_getInstanceMethod(self, originalSelector2);
    Method overrideMethod2 = class_getInstanceMethod(self, overrideSelector2);

    if (class_addMethod(self, originalSelector2, method_getImplementation(overrideMethod2), method_getTypeEncoding(overrideMethod2)))
	{
		class_replaceMethod(self, overrideSelector2, method_getImplementation(originalMethod2), method_getTypeEncoding(originalMethod2));
    }
	else
	{
		method_exchangeImplementations(originalMethod2, overrideMethod2);
    }
    
    SEL originalSelector3 = @selector(removeFromSuperview:);
    SEL overrideSelector3 = @selector(customRemoveFromSuperview:);
    Method originalMethod3 = class_getInstanceMethod(self, originalSelector3);
    Method overrideMethod3 = class_getInstanceMethod(self, overrideSelector3);

    if (class_addMethod(self, originalSelector3, method_getImplementation(overrideMethod3), method_getTypeEncoding(overrideMethod3)))
	{
		class_replaceMethod(self, overrideSelector3, method_getImplementation(originalMethod3), method_getTypeEncoding(originalMethod3));
    }
	else
	{
		method_exchangeImplementations(originalMethod3, overrideMethod3);
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if([self respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)])
    {
        [self setBackgroundImage:[UIImage imageNamed:@"bar_clear.png"] forBarMetrics:UIBarMetricsDefault];
    }
    [self setCustomBGLayer:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [self setCaption:@""];
}

- (void)customRemoveFromSuperview
{
    [self customRemoveFromSuperview];
}

- (void)customDrawRect:(CGRect)rect
{
    [[UIColor blackColor] set];      
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
}

- (void)customLayoutSubviews
{
    [self customLayoutSubviews];
    
    CALayer *customLayer = [self getCustomBGLayer];
    if(customLayer)
    {
        [self.layer insertSublayer:customLayer below:[[self.layer sublayers] objectAtIndex:0]];
    }
}

- (void)setCustomBGLayer:(CGRect)rect
{
    CALayer *customLayer = [self getCustomBGLayer];

    if(customLayer == nil)
    {
        customLayer = [[[CALayer alloc] init] autorelease];
        [customLayer setName:@"customBGLayer"];
        customLayer.needsDisplayOnBoundsChange = YES;
        customLayer.masksToBounds = NO;
        customLayer.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0].CGColor;
        customLayer.frame = CGRectMake(0, -20, rect.size.width, rect.size.height+20);
    }
    [self.layer insertSublayer:customLayer below:[[self.layer sublayers] objectAtIndex:0]];

    [self setDropShadow];
}

- (CALayer*)getCustomBGLayer
{
    CALayer *customLayer = nil;

    for(CALayer *layer in [self.layer sublayers])
    {
        if([layer.name isEqualToString:@"customBGLayer"])
        {
            customLayer = layer;
            break;
        }
    }
    
    return customLayer;
}

- (void)resizeBGLayer:(CGRect)frame
{
    CALayer *customLayer = [self getCustomBGLayer];
    if(customLayer == nil)
    {
        [self setCustomBGLayer:frame];
    }
    else
    {
        [customLayer setFrame:CGRectMake(0, frame.origin.y-20, frame.size.width, frame.size.height+20)];
        [self setDropShadow];
    }
}

- (void)removeCaptions
{
    UIView *captionView = [self viewWithTag:10];

    if(captionView != nil && captionView.hidden == NO)
    {
        [UIView beginAnimations:@"hideCaption" context:nil];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [captionView setAlpha:0];
        [UIView commitAnimations];
        [captionView performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.3];
    }
}

- (void)setCaption:(NSString*)caption
{
    if([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationPortrait)
    {
        UIView *captionView = [self viewWithTag:10];
        
        if(captionView == nil)
        {
            //create new caption view
            captionView = [[[UIView alloc] initWithFrame:CGRectMake(self.frame.origin.x, 34, 320, 14)] autorelease];
            [captionView setTag:10];
            [captionView setBackgroundColor:[UIColor clearColor]];

            UILabel *captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, captionView.frame.size.width, captionView.frame.size.height)];
            [captionLabel setText:caption];
            [captionLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:12.0]];
            [captionLabel setTextColor:[UIColor colorWithWhite:0.6 alpha:1.0]];
            [captionLabel setBackgroundColor:[UIColor clearColor]];
            [captionLabel setTextAlignment:UITextAlignmentCenter];
            [captionLabel setTag:1];
            [captionView addSubview:captionLabel];
            [captionLabel release];
            
            [self addSubview:captionView];
            
            if(![caption isEqualToString:@""])
            {
                [captionView setAlpha:0];
                [captionView setHidden:NO];
                [UIView beginAnimations:@"showCaption" context:nil];
                [UIView setAnimationDuration:0.25];
                [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                [captionView setAlpha:1.0];
                [UIView commitAnimations];
            }
        }
        else
        {
            [captionView setAlpha:1.0];
            [captionView setHidden:NO];
            UILabel *currentLabel = (UILabel*)[captionView viewWithTag:1];
            [currentLabel setText:caption];
        }
    }
}

- (void)hideDropShadow
{
	CALayer *customLayer = [self getCustomBGLayer];

    if(customLayer)
    {
        customLayer.shadowColor = [[UIColor clearColor] CGColor];
        customLayer.shadowOffset = CGSizeMake(0.0, 0.0);
        customLayer.shadowOpacity = 0.0;
    }
}

- (void)setDropShadow
{
    CALayer *customLayer = [self getCustomBGLayer];
    
    if(customLayer)
    {
        UIBezierPath *path = [UIBezierPath bezierPath];	
        
        CGPoint topLeft		 = customLayer.frame.origin;
        CGPoint bottomLeft	 = CGPointMake(-50.0, customLayer.frame.size.height);
        CGPoint bottomRight	 = CGPointMake(customLayer.frame.size.width + 50, customLayer.frame.size.height);
        CGPoint topRight	 = CGPointMake(customLayer.frame.size.width + 50, customLayer.frame.origin.y);
        
        [path moveToPoint:topLeft];	
        [path addLineToPoint:bottomLeft];
        [path addLineToPoint:bottomRight];
        [path addLineToPoint:topRight];
        [path addLineToPoint:topLeft];
        [path closePath];
        
        // add the drop shadow
        customLayer.shadowColor = [[UIColor blackColor] CGColor];
        customLayer.shadowOffset = CGSizeMake(0.0, 3.0);
        customLayer.shadowOpacity = 0.5;
        customLayer.shadowPath = path.CGPath;
    }
}

@end