//
//  UINavigationItem+CustomTitle.m
//  YongoPal
//
//  Created by Jiho Kang on 8/1/11.
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

#import "UINavigationItem+CustomTitle.h"

@implementation UINavigationItem (CustomTitle)

- (void)setCustomTitle:(NSString*)title
{
    CGRect frame = CGRectMake(60, 0, 200, 44);

    UIView *titleView = [[UIView alloc] initWithFrame:frame];;

    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)] autorelease];
    [label setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:20.0]];
    [label setShadowColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setTextColor:UIColorFromRGB(0xC7C7C7)];
    [label setText:title];
    [titleView addSubview:label];
    
    UIButton *debugButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 44)] autorelease];
    [debugButton setBackgroundColor:[UIColor clearColor]];
    [debugButton setTag:1];
    [titleView addSubview:debugButton];
    
    [self setTitleView:titleView];
    [titleView release];
}

@end
