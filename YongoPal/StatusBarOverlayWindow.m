//
//  StatusBarOverlayWindow.m
//  Wander
//
//  Created by Jiho Kang on 5/29/13.
//  Copyright (c) 2013 YongoPal, Inc. All rights reserved.
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

#import "StatusBarOverlayWindow.h"
#import "YongoPalAppDelegate.h"

@implementation StatusBarOverlayWindow
@synthesize networkErrorView;

- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame]))
    {
        // Place the window on the correct level and position
        self.windowLevel = UIWindowLevelStatusBar+1.0f;
        self.frame = [[UIApplication sharedApplication] statusBarFrame];
        [self setUserInteractionEnabled:NO];

        YongoPalAppDelegate *appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        if([appDelegate.networkStatus boolValue] == NO)
        {
            [self showOverlay];
        }
    }
    return self;
}

- (void)dealloc
{
    self.networkErrorView = nil;
    [super dealloc];
}

- (void)showOverlay
{
    if(self.networkErrorView == nil)
    {
        self.networkErrorView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.window.frame.size.width, 20)] autorelease];
        [self.networkErrorView setBackgroundColor:UIColorFromRGB(0x990000)];
        [self.networkErrorView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self.networkErrorView setAutoresizesSubviews:YES];
        
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.frame];
        [backgroundImageView setImage:[UIImage imageNamed:@"bar_pink.png"]];
        [backgroundImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self.networkErrorView addSubview:backgroundImageView];
        [backgroundImageView release];
        
        UIImage *alertImage = [[UIImage imageNamed:@"184-warning.png"] resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(17, 13) interpolationQuality:kCGInterpolationHigh];
        UIImageView *alertImageView = [[UIImageView alloc] initWithImage:alertImage];
        [alertImageView setFrame:CGRectMake(85, 3, 17, 13)];
        [alertImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [alertImageView setContentMode:UIViewContentModeCenter];
        [self.networkErrorView addSubview:alertImageView];
        [alertImageView release];
        
        UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 2, 125, 16)];
        [errorLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [errorLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:12.0]];
        [errorLabel setTextAlignment:NSTextAlignmentCenter];
        [errorLabel setTextColor:[UIColor whiteColor]];
        [errorLabel setBackgroundColor:[UIColor clearColor]];
        [errorLabel setText:@"No Internet Connection"];
        [self.networkErrorView addSubview:errorLabel];
        [errorLabel release];

        [self.networkErrorView setAlpha:0];
        [self addSubview:self.networkErrorView];
        
        [UIView beginAnimations:@"fadeIn" context:nil];
        [UIView setAnimationDuration:0.5];
        [self.networkErrorView setAlpha:1];
        [UIView commitAnimations];
    }
}

- (void)shouldRotateOverlay:(UIInterfaceOrientation)orientation
{
    if(UIInterfaceOrientationIsPortrait(orientation))
    {
        self.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
    }
    else if(UIInterfaceOrientationIsLandscape(orientation))
    {
        if(UIInterfaceOrientationLandscapeLeft == orientation)
        {
            self.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
        }
        else if(UIInterfaceOrientationLandscapeRight == orientation)
        {
            self.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
        }
    }
}

- (void)hideOverlay
{
    if(self.networkErrorView)
    {
        [UIView beginAnimations:@"fadeOut" context:nil];
        [UIView setAnimationDuration:0.5];
        [self.networkErrorView setAlpha:0];
        [UIView commitAnimations];
        
        [self performSelector:@selector(removeNetworkErrorView) withObject:nil afterDelay:1.0];
    }
}

- (void)removeNetworkErrorView
{
    [self.networkErrorView removeFromSuperview];
    self.networkErrorView = nil;
}



@end
