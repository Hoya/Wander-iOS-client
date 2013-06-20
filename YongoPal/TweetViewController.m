//
//  TweetViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 6/23/11.
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

#import "TweetViewController.h"


@implementation TweetViewController
@synthesize tweetContainer;
@synthesize twitter;
@synthesize tweetText;
@synthesize bgView;
@synthesize charCount;
@synthesize linkUrl;
@synthesize linkLabel;
@synthesize thumbnailImage;
@synthesize thumbnailView;
@synthesize imageKey;
@synthesize matchNo;
@synthesize isOwner;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)dealloc
{
    [tweetContainer release];
	[twitter release];
	[tweetText release];
	[bgView release];
	[charCount release];
    [linkLabel release];
    [thumbnailView release];
    [linkUrl release];
    [thumbnailImage release];
    [imageKey release];
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

    [self.navigationItem setCustomTitle:NSLocalizedString(@"twitterTitle", nil)];

	SA_OAuthTwitterEngine *twitterController = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
    [twitterController setConsumerKey:twitterKey];
    [twitterController setConsumerSecret:twitterSecret];
    self.twitter = twitterController;
    [twitterController release];

	UIImage *cancelImage = [UIImage imageNamed:@"btn_x.png"];
	CGRect cancelFrame = CGRectMake(0, 0, cancelImage.size.width, cancelImage.size.height);
	CUIButton *cancelButton = [[CUIButton alloc] initWithFrame:cancelFrame];
	[cancelButton setBackgroundImage:cancelImage forState:UIControlStateNormal];
	[cancelButton setShowsTouchWhenHighlighted:YES];
	[cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
	[self.navigationItem setLeftBarButtonItem:cancelBarButtonItem];
	[cancelBarButtonItem release];
	[cancelButton release];

	UIImage *doneImage = [UIImage imageNamed:@"btn_check.png"];
	CGRect doneFrame = CGRectMake(0, 0, doneImage.size.width, doneImage.size.height);
	CUIButton *doneButton = [[CUIButton alloc] initWithFrame:doneFrame];
	[doneButton setBackgroundImage:doneImage forState:UIControlStateNormal];
	[doneButton setShowsTouchWhenHighlighted:YES];
	[doneButton addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
	[self.navigationItem setRightBarButtonItem:doneBarButtonItem];
	[doneBarButtonItem release];
	[doneButton release];

	bgView.layer.shadowOpacity = 0.3;
	bgView.layer.shadowRadius = 1.0;
	bgView.layer.shadowColor = [[UIColor blackColor] CGColor];
	bgView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
}

- (void)viewDidUnload
{    
    [super viewDidUnload];

    self.tweetContainer = nil;
    self.twitter = nil;
	self.tweetText = nil;
	self.bgView = nil;
	self.charCount = nil;
    self.linkLabel = nil;
    self.thumbnailView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    int linkLength = [linkUrl length] + 1;
    int tweetLength = [tweetText.text length];
    int limit = 140 - linkLength;

    [tweetText setContentInset:UIEdgeInsetsMake(9, -8, 0, 0)];
	[tweetText setSelectedRange:NSMakeRange(0, 0)];
	[tweetText becomeFirstResponder];
	[charCount setText:[NSString stringWithFormat:@"%d", (limit - tweetLength)]];
    
    [linkLabel setText:linkUrl];

    [thumbnailView.layer setMasksToBounds:YES];
	[thumbnailView.layer setCornerRadius:4];
    [thumbnailView setImage:thumbnailImage];

	[super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        // resize the navbar
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, 480, 32)];
        [[self.navigationController navigationBar] removeCaptions];

        return YES;
    }
    else if(interfaceOrientation == UIInterfaceOrientationPortrait)
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

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {        
        CGRect newFrame = self.tweetContainer.frame;
        newFrame.size.width = 480;
        newFrame.size.height = 106;
        [self.tweetContainer setFrame:newFrame];
    }
    else
    {   
        CGRect newFrame = self.tweetContainer.frame;
        newFrame.size.width = 320;
        newFrame.size.height = 200;
        [self.tweetContainer setFrame:newFrame];
    }
}

- (void)cancel
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)send
{
	if([twitter isAuthorized] == YES)
	{
        int linkLength = [linkUrl length] + 1;
        int tweetLength = [tweetText.text length];
        int limit = 140 - linkLength;

        if(tweetLength > limit)
        {
            NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Oops", @"title", @"Your tweet is too long!", @"message", nil];
            [appDelegate displayAlert:alertContent];
            [alertContent release];
            
            [appDelegate didStopNetworking];
            [appDelegate hideLoading];
        }
        else
        {
            [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"tweetPhoto"];
            
            [appDelegate didStartNetworking];
            [appDelegate showLoading];
            [twitter sendUpdate:[NSString stringWithFormat:@"%@ %@", tweetText.text, linkUrl]];
            [tweetText resignFirstResponder];
            
            if(isOwner == NO)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldConfirmCrossPost" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.imageKey, @"key", @"TWT", @"postType", nil]];
            }
        }
	}
	else
	{
		NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Request Failed", @"title", @"Invalid API Token", @"message", nil];
		[appDelegate displayAlert:alertContent];
		[alertContent release];
		
		[self dismissModalViewControllerAnimated:YES];
	}
}

- (void)textViewDidChange:(UITextView *)textView
{
    int linkLength = [linkUrl length] + 1;
    int tweetLength = [tweetText.text length];
    int limit = 140 - linkLength;

	if([textView.text length] > limit)
	{
		[charCount setTextColor:[UIColor redColor]];
	}
	else
	{
		[charCount setTextColor:[UIColor colorWithWhite:0.55 alpha:1.0]];
	}
	[charCount setText:[NSString stringWithFormat:@"%d", (limit - tweetLength)]];
}

#pragma mark - twitter delegate
- (NSString *) cachedTwitterOAuthDataForUsername: (NSString *) username
{
	return [appDelegate.prefs objectForKey:@"TwitterAuthData"];
}

- (void) requestSucceeded: (NSString *) requestIdentifier
{
	[appDelegate hideLoading];
	[appDelegate didStopNetworking];
	[self dismissModalViewControllerAnimated:YES];
}

- (void) requestFailed: (NSString *) requestIdentifier withError: (NSError *) error
{
	[appDelegate hideLoading];
	[appDelegate didStopNetworking];
	NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Request Failed", @"title", [NSString stringWithFormat:@"%@", error], @"message", nil];
	[appDelegate displayAlert:alertContent];
	[alertContent release];
	[tweetText becomeFirstResponder];
}

- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier
{
	//NSLog(@"Recieved Object: %@", dictionary);
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier {
	
	//NSLog(@"Misc Info Received: %@", miscInfo);
}

@end
