//
//  LogViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 7/15/11.
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

#import "LogViewController.h"

@implementation LogViewController
@synthesize logData;
@synthesize logTextView;
@synthesize logString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self.navigationItem setCustomTitle:@"View Log"];
    }
    return self;
}

- (void)dealloc
{
	[logData release];
	[logTextView release];
    self.logString = nil;
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
	
	UIImage *backImage = [UIImage imageNamed:@"btn_back.png"];
	CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
	UIButton *backButton = [[UIButton alloc] initWithFrame:backFrame];
	[backButton setBackgroundImage:backImage forState:UIControlStateNormal];
	[backButton setShowsTouchWhenHighlighted:YES];
	[backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
	[self.navigationItem setLeftBarButtonItem:backBarButtonItem];
	[backBarButtonItem release];
	[backButton release];

	UIBarButtonItem *copyBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(copyLogData)];
    [copyBarButtonItem setTintColor:[UIColor blackColor]];
	[self.navigationItem setRightBarButtonItem:copyBarButtonItem];
	[copyBarButtonItem release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.logData = nil;
	self.logTextView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    id requestData = [jsonParser objectWithString:[logData valueForKey:@"requestData"] error:nil];
    id resultData = [jsonParser objectWithString:[logData valueForKey:@"resultData"] error:nil];
    [jsonParser release];
    
    SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
    [jsonWriter setHumanReadable:YES];
    NSString *requestDataString = [jsonWriter stringWithObject:requestData];
    NSString *resultDataString = [jsonWriter stringWithObject:resultData];
    [jsonWriter release];

	self.logString = [NSString stringWithFormat:@"*server: %@", [logData valueForKey:@"server"]];
	self.logString = [NSString stringWithFormat:@"%@\n\n*request: %@", self.logString, [logData valueForKey:@"requestType"]];
	self.logString = [NSString stringWithFormat:@"%@\n\n*task: %@", self.logString, [logData valueForKey:@"task"]];
	self.logString = [NSString stringWithFormat:@"%@\n\n*requestData: %@", self.logString, requestDataString];
	self.logString = [NSString stringWithFormat:@"%@\n\n*resultData: %@", self.logString, resultDataString];
	self.logString = [NSString stringWithFormat:@"%@\n\n*date: %@", self.logString, [logData valueForKey:@"datetime"]];
	
	[self.logTextView setText:[NSString stringWithFormat:@"%@", self.logString]];
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
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)copyLogData
{
    if([self.logString length] > 0)
    {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:self.logString];
        
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Cool"
                              message:@"The log data has been copied to your clipboard"
                              delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
        [alert show];
        [alert release];
    }
}

@end
