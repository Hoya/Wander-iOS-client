//
//  InputViewController.m
//  Wander
//
//  Created by Jiho Kang on 10/24/11.
//  Copyright (c) 2011 YongoPal, Inc. All rights reserved.
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

#import "InputViewController.h"
#import "UINavigationItem+CustomTitle.h"
#import "CUIButton.h"

@implementation InputViewController
@synthesize delegate;
@synthesize navTitle;
@synthesize inputField;
@synthesize defaultInputValue;
@synthesize keyboardType;
@synthesize tag;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    self.navTitle = nil;
    self.inputField = nil;
    self.defaultInputValue = nil;
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.navigationItem setCustomTitle:navTitle];

    UIImage *backImage = [UIImage imageNamed:@"btn_back.png"];
    CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
    CUIButton *backButton = [[CUIButton alloc] initWithFrame:backFrame];
    [backButton setBackgroundImage:backImage forState:UIControlStateNormal];
    [backButton setShowsTouchWhenHighlighted:YES];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backBarButtonItem];
    [backBarButtonItem release];
    [backButton release];
    
    UIImage *saveImage = [UIImage imageNamed:@"btn_save.png"];
    CGRect saveFrame = CGRectMake(0, 0, saveImage.size.width, saveImage.size.height);
    CUIButton *saveButton = [[CUIButton alloc] initWithFrame:saveFrame];
    [saveButton setBackgroundImage:saveImage forState:UIControlStateNormal];
    [saveButton setShowsTouchWhenHighlighted:YES];
    [saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *saveBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    [self.navigationItem setRightBarButtonItem:saveBarButtonItem];
    [saveBarButtonItem release];
    [saveButton release];
    
    [self.inputField setKeyboardType:keyboardType];
    [self.inputField setText:defaultInputValue];
    [self.inputField becomeFirstResponder];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.inputField = nil;
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

- (void)save
{
    if([self.inputField.text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Oops"
                              message:@"You must input something"
                              delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
        [alert setTag:99];
        [alert show];
        [alert release];
    }
    else
    {
        [delegate valueSet:self.inputField.text sender:tag];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
