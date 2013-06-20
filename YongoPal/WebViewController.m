//
//  WebViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 8/5/11.
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

#import "WebViewController.h"

@implementation WebViewController
@synthesize webView;
@synthesize spinner;
@synthesize url;
@synthesize navTitle;
@synthesize isModalView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)dealloc
{
    [spinner release];
    [webView release];
    [url release];
    [navTitle release];
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

    //Create a URL object.
    NSURL *requestUrl = [NSURL URLWithString:url];
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:requestUrl];
    
    //Load the request in the UIWebView.
    [webView loadRequest:requestObj];

    // set title
    [self.navigationItem setCustomTitle:navTitle];
    
    // set navigation buttons
	UIImage *backImage = nil;
    if(isModalView == YES)
    {
        backImage = [UIImage imageNamed:@"btn_x.png"];
    }
    else
    {
        backImage = [UIImage imageNamed:@"btn_back.png"];
    }
	CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
	CUIButton *backButton = [[CUIButton alloc] initWithFrame:backFrame];
	[backButton setBackgroundImage:backImage forState:UIControlStateNormal];
	[backButton setShowsTouchWhenHighlighted:YES];
	[backButton addTarget:self action:@selector(closeWebview) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
	[self.navigationItem setLeftBarButtonItem:backBarButtonItem];
	[backBarButtonItem release];
	[backButton release];
    
    if(isModalView == YES)
    {
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.spinner = nil;
    self.webView = nil;
    self.url = nil;
    self.navTitle = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [spinner stopAnimating];
    [appDelegate didStopNetworking];
    [super viewWillDisappear:animated];
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

- (void)closeWebview
{
    if(isModalView == YES)
    {
        [self dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [spinner startAnimating];
    [appDelegate didStartNetworking];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [UIView beginAnimations:@"showWebView" context:nil];
	[UIView setAnimationDelay:0.5];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[self.webView setAlpha:1.0];
	[UIView commitAnimations];
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [spinner stopAnimating];
    [appDelegate didStopNetworking];
    [self.navigationItem.leftBarButtonItem setEnabled:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [appDelegate didStopNetworking];
    [self.navigationItem.leftBarButtonItem setEnabled:YES];
}

@end
