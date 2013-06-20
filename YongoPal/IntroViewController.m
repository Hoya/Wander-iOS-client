//
//  IntroViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 6/28/11.
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

#import "IntroViewController.h"
#import "ProfileViewController.h"
#import "UtilityClasses.h"

@implementation IntroViewController
@synthesize scrollView;
@synthesize _pageControl;
@synthesize intro1;
@synthesize intro2;
@synthesize intro3;
@synthesize intro4;
@synthesize intro5;
@synthesize backButton;
@synthesize forwardButton;
@synthesize startButton;
@synthesize shouldShowProfile;
@synthesize completeProfileButton;

@synthesize introTitle1;
@synthesize introTitle2;
@synthesize introTitle3;
@synthesize introTitle4;
@synthesize introTitle5;
@synthesize introSub1;
@synthesize introSub2;
@synthesize introSub3;
@synthesize introSub4;
@synthesize introSub5;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
	[scrollView release];
	[_pageControl release];
	
	[intro1 release];
	[intro2 release];
	[intro3 release];
	[intro4 release];
	[intro5 release];
	[backButton release];
	[forwardButton release];
	[startButton release];
    [completeProfileButton release];
    
    [introTitle1 release];
    [introTitle2 release];
    [introTitle3 release];
    [introTitle4 release];
    [introTitle5 release];
    [introSub1 release];
    [introSub2 release];
    [introSub3 release];
    [introSub4 release];
    [introSub5 release];
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

	currentPage = intro1;
	nextPage = intro2;
	currentPageNumber = 0;

	scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * 5, scrollView.frame.size.height);
	scrollView.contentOffset = CGPointMake(0, 0);
	
	_pageControl = [[PageControl alloc] initWithFrame:CGRectMake(0, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO]-41, 320, 36)];
	[_pageControl setNumberOfPages:5];
	[_pageControl setCurrentPage:0];
	[_pageControl setDelegate:self];
	[self.view insertSubview:_pageControl belowSubview:startButton];
	[self pageControlPageDidChange:_pageControl];

	[scrollView addSubview:intro1];
	[scrollView addSubview:intro2];
	[scrollView addSubview:intro3];
	[scrollView addSubview:intro4];
	[scrollView addSubview:intro5];
	
	[self applyNewIndex:0 pageView:intro1];
	[self applyNewIndex:1 pageView:intro2];
	[self applyNewIndex:2 pageView:intro3];
	[self applyNewIndex:3 pageView:intro4];
	[self applyNewIndex:4 pageView:intro5];

    [introTitle1 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:38]];
    [introTitle2 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:38]];
    [introTitle3 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:38]];
    [introTitle4 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:38]];
    [introTitle5 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:38]];

    [introSub1 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:26]];
    [introSub2 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:26]];
    [introSub3 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:26]];
    [introSub4 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:26]];
    [introSub5 setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:26]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    if(shouldShowProfile == YES)
    {
        [completeProfileButton setHidden:NO];
        [startButton addTarget:self action:@selector(showProfile) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [completeProfileButton setHidden:YES];
        [startButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.scrollView = nil;
    self._pageControl = nil;
    self.intro1 = nil;
    self.intro2 = nil;
    self.intro3 = nil;
    self.intro4 = nil;
    self.intro5 = nil;
    
    self.introTitle1 = nil;
    self.introTitle2 = nil;
    self.introTitle3 = nil;
    self.introTitle4 = nil;
    self.introTitle5 = nil;
    
    self.introSub1 = nil;
    self.introSub2 = nil;
    self.introSub3 = nil;
    self.introSub4 = nil;
    self.introSub5 = nil;
    
    self.backButton = nil;
    self.forwardButton = nil;
    self.startButton = nil;
    self.completeProfileButton = nil;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)goBack
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)applyNewIndex:(NSInteger)newIndex pageView:(UIView *)pageView
{
	NSInteger pageCount = 5;
	BOOL outOfBounds = newIndex >= pageCount || newIndex < 0;
	
	if (!outOfBounds)
	{
		CGRect pageFrame = pageView.frame;
		pageFrame.origin.y = 0;
		pageFrame.origin.x = scrollView.frame.size.width * newIndex;
		pageView.frame = pageFrame;
	}
	else
	{
		CGRect pageFrame = pageView.frame;
		pageFrame.origin.y = scrollView.frame.size.height;
		pageView.frame = pageFrame;
	}
}

- (IBAction)showProfile
{
	ProfileViewController *profileController = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController" bundle:nil];
	profileController.firstSignup = YES;
	[self.navigationController pushViewController:profileController animated:YES];
	[profileController release];
}

#pragma mark - scrollViewDelegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)newScrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
	NSInteger nearestNumber = lround(fractionalPage);
	
	currentPage = [self.view viewWithTag:nearestNumber];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)newScrollView
{
	[self scrollViewDidEndScrollingAnimation:newScrollView];
	_pageControl.currentPage = currentPage.tag;

	[self pageControlPageDidChange:_pageControl];
	
	if(_pageControl.currentPage == 0)
	{
		[backButton setHidden:YES];
		[forwardButton setHidden:NO];
		[startButton setHidden:YES];
	}
	else if(_pageControl.currentPage == 4)
	{
		[backButton setHidden:NO];
		[forwardButton setHidden:YES];
		if(shouldShowProfile == NO) [startButton setHidden:NO];
	}
	else
	{
		[backButton setHidden:NO];
		[forwardButton setHidden:NO];
		[startButton setHidden:YES];
	}
}

- (IBAction)changePage:(id)sender
{
	NSInteger pageIndex = _pageControl.currentPage;

	[self pageControlPageDidChange:_pageControl];

	// update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * pageIndex;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];
	
	if(pageIndex == 0)
	{
		[backButton setHidden:YES];
		[forwardButton setHidden:NO];
		[startButton setHidden:YES];
	}
	else if(pageIndex == 4)
	{
		[backButton setHidden:NO];
		[forwardButton setHidden:YES];
		[startButton setHidden:NO];
	}
	else
	{
		[backButton setHidden:NO];
		[forwardButton setHidden:NO];
		[startButton setHidden:YES];
	}
}

- (void)pageControlPageDidChange:(PageControl *)pageControl
{
	int page = pageControl.currentPage + 1;
	if(currentPageNumber != page)
	{
		currentPageNumber = page;
	}
}

@end
