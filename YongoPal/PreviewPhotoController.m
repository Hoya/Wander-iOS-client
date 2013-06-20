//
//  PreviewPhotoController.m
//  YongoPal
//
//  Created by Jiho Kang on 6/16/11.
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

#import "PreviewPhotoController.h"
#import "SharePhotoController.h"
#import "UtilityClasses.h"

@implementation PreviewPhotoController
@synthesize toolbar;
@synthesize previewImage;
@synthesize receivedPhoto;
@synthesize spinner;
@synthesize matchNo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
		appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)dealloc
{
	[toolbar release];
	[previewImage release];
    [spinner release];
	[receivedPhoto release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // set navigation buttons
    UIImage *backImage = [UIImage imageNamed:@"btn_back.png"];
    CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
    CUIButton *backButton = [[CUIButton alloc] initWithFrame:backFrame];	
    [backButton setImage:backImage forState:UIControlStateNormal];
    [backButton setShowsTouchWhenHighlighted:YES];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backBarButtonItem];
    [backBarButtonItem release];
    [backButton release];
    
    [self performSelector:@selector(setPreview) withObject:nil afterDelay:0.0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationItem setCustomTitle:@"Preview Photo"];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

	self.toolbar = nil;
	self.previewImage = nil;
    self.spinner = nil;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationIsPortrait(UIInterfaceOrientationPortrait);
}

- (bool)orientationChanged:(NSNotification *)notification
{
    UIInterfaceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    
    if(UIDeviceOrientationIsLandscape(currentOrientation))
    {
        // resize the navbar
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, [UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO], 32)];
        [[self.navigationController navigationBar] removeCaptions];
        
        return YES;
    }
    else if(UIDeviceOrientationIsPortrait(currentOrientation))
    {
        // resize the navbar
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, 320, 44)];
        
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self orientationChanged:nil];
}

- (IBAction)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setPreview
{
    [self.previewImage setImage:[receivedPhoto resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(640, 960) interpolationQuality:kCGInterpolationDefault]];
    [self.spinner stopAnimating];
}

@end
