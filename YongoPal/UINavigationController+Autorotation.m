//
//  UINavigationController+Autorotation.m
//  Wander
//
//  Created by Jiho Kang on 5/22/13.
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

#import "UINavigationController+Autorotation.h"

@implementation UINavigationController (Autorotation)

-(BOOL)shouldAutorotate
{
    if([[self.viewControllers lastObject] respondsToSelector:@selector(shouldAutorotate)])
    {
        return [[self.viewControllers lastObject] shouldAutorotate];
    }
    else
    {
        return NO;
    }
}

-(NSUInteger)supportedInterfaceOrientations
{
    if([[self.viewControllers lastObject] shouldAutorotate] == NO || ![[self.viewControllers lastObject] respondsToSelector:@selector(supportedInterfaceOrientations)])
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    else
    {
        return [[self.viewControllers lastObject] supportedInterfaceOrientations];
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if([[self.viewControllers lastObject] respondsToSelector:@selector(preferredInterfaceOrientationForPresentation)])
    {
        return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
    }
    else
    {
        return UIDeviceOrientationPortrait;
    }
}

@end
