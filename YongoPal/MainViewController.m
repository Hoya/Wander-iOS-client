//
//  MainViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 4/6/11.
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

#import "MainViewController.h"
#import "ProfileViewController.h"
#import "IntroViewController.h"
#import "MatchListViewController.h"
#import "WebViewController.h"
#import "UtilityClasses.h"

@implementation MainViewController
@synthesize topBarView;
@synthesize topBarTitle;
@synthesize logoImage;
@synthesize loginBtnContainer;
@synthesize signupBtnContainer;
@synthesize buttonContainer;
@synthesize signupContainer;
@synthesize signupButton;
@synthesize loginButton;
@synthesize forgotButton;
@synthesize loginContainer;
@synthesize loginTextContainer;
@synthesize emailField;
@synthesize passwordField;
@synthesize signupView;
@synthesize signupScrollView;
@synthesize firstNameField;
@synthesize lastNameField;
@synthesize nameFieldContainer;
@synthesize emailField2;
@synthesize emailFieldContainer;
@synthesize passwordField2;
@synthesize passwordFieldContainer;
@synthesize termsButton;
@synthesize policyButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:4];
        
        // register keyboard notifiers
        [self registerKeyboardNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [operationQueue cancelAllOperations];
    [operationQueue release];
	[topBarView release];
	[topBarTitle release];
	[logoImage release];
	[buttonContainer release];
	[signupBtnContainer release];
	[loginBtnContainer release];
	[signupContainer release];
	[loginContainer release];
	[loginTextContainer release];
	[signupButton release];
	[loginButton release];
    [forgotButton release];
	[emailField release];
	[passwordField release];
	[signupView release];
	[signupScrollView release];
	[firstNameField release];
	[lastNameField release];
	[nameFieldContainer release];
	[emailField2 release];
	[emailFieldContainer release];
	[passwordField2 release];
	[passwordFieldContainer release];
    [termsButton release];
    [policyButton release];

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

	appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
    [self.forgotButton setFrame:CGRectMake(forgotButton.frame.origin.x, 16, 12, 12)];
    [self.forgotButton setHitErrorMargin:20];
    
    [self loadLoginView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.view = nil;
	self.topBarView = nil;
	self.topBarTitle = nil;
	self.logoImage = nil;
	self.signupBtnContainer = nil;
	self.loginBtnContainer = nil;
    self.buttonContainer = nil;
	self.signupContainer = nil;
	self.loginTextContainer = nil;
	self.loginContainer = nil;
	self.signupButton = nil;
	self.loginButton = nil;
    self.forgotButton = nil;
	self.emailField = nil;
	self.passwordField = nil;
	self.signupView = nil;
	self.signupScrollView = nil;
	self.firstNameField = nil;
	self.lastNameField = nil;
	self.nameFieldContainer = nil;
	self.emailField2 = nil;
	self.emailFieldContainer = nil;
	self.passwordField2 = nil;
	self.passwordFieldContainer = nil;
    self.termsButton = nil;
    self.policyButton = nil;

    keyboardVisible = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStateChanged:) name:YPSessionStateChangedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    [self showButtons];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if(currentView > 0 && currentView < 3) [self didCancel];
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YPSessionStateChangedNotification object:nil];
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

#pragma mark - functions
- (void)registerKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardDidShow:) name: UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardDidHide:) name: UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
}

- (void)loadLoginView
{
    [self.view insertSubview:buttonContainer belowSubview:topBarView];
	[buttonContainer setFrame:CGRectMake(0, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO], buttonContainer.frame.size.width, buttonContainer.frame.size.height)];
	[topBarView setAlpha:0.0];
	
	[loginTextContainer.layer setMasksToBounds:YES];
	[loginTextContainer.layer setCornerRadius:5.0];
	[loginTextContainer.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[loginTextContainer.layer setBorderWidth: 1.0];
    
	[nameFieldContainer.layer setMasksToBounds:YES];
	[nameFieldContainer.layer setCornerRadius:5.0];
	[nameFieldContainer.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[nameFieldContainer.layer setBorderWidth: 1.0];
	
	[emailFieldContainer.layer setMasksToBounds:YES];
	[emailFieldContainer.layer setCornerRadius:5.0];
	[emailFieldContainer.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[emailFieldContainer.layer setBorderWidth: 1.0];
	
	[passwordFieldContainer.layer setMasksToBounds:YES];
	[passwordFieldContainer.layer setCornerRadius:5.0];
	[passwordFieldContainer.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[passwordFieldContainer.layer setBorderWidth: 1.0];
    
    [termsButton.layer setMasksToBounds:YES];
	[termsButton.layer setCornerRadius:5.0];
	[termsButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5] forState:UIControlStateNormal];
	[termsButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
    
    [policyButton.layer setMasksToBounds:YES];
	[policyButton.layer setCornerRadius:5.0];
	[policyButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5] forState:UIControlStateNormal];
	[policyButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
}

- (void)showButtons
{
	[UIView beginAnimations:@"showButtons" context:nil];
	[UIView setAnimationDelay:1.0];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[buttonContainer setFrame:CGRectMake(0, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO] - signupBtnContainer.frame.size.height, buttonContainer.frame.size.width, buttonContainer.frame.size.height)];
	[UIView commitAnimations];
}

- (IBAction)hideOptions
{
	currentView = 0;
	[signupBtnContainer setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.7]];
	[signupButton setAlpha:1.0];
	
	[loginBtnContainer setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.7]];
	[loginButton setAlpha:1.0];

	[UIView beginAnimations:@"showSignup" context:nil];
	[UIView setAnimationDuration:0.25];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[buttonContainer setFrame:CGRectMake(0, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO] - signupBtnContainer.frame.size.height, buttonContainer.frame.size.width, buttonContainer.frame.size.height)];

    if([UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO] < 568)
    {
        [logoImage setFrame:CGRectMake(48, 65, 225, 200)];
    }
    else
    {
        [logoImage setFrame:CGRectMake(logoImage.frame.origin.x, 65, logoImage.frame.size.width, logoImage.frame.size.height)];
    }
	
	[UIView commitAnimations];
}

- (IBAction)signup
{
    [appDelegate.matchlistController setIsFirstRun:YES];
	currentView = 1;

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"touchSignup"];

	[self.view addSubview:signupView];
	[signupView setFrame:CGRectMake(0, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO], signupView.frame.size.width, signupView.frame.size.height)];

	[signupContainer setHidden:NO];
	[loginContainer setHidden:YES];
	
	[signupBtnContainer setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.7]];
	[signupButton setAlpha:1.0];
	
	[loginBtnContainer setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.85]];
	[loginButton setAlpha:0.2];

	[UIView beginAnimations:@"showSignup" context:nil];
	[UIView setAnimationDuration:0.25];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    float y = [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO] - signupBtnContainer.frame.size.height - signupContainer.frame.size.height;
	[buttonContainer setFrame:CGRectMake(0, y, buttonContainer.frame.size.width, buttonContainer.frame.size.height)];
    if([UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO] < 568)
    {
        [logoImage setFrame:CGRectMake(81, 16, 158, 140)];
    }
    else
    {
        [logoImage setFrame:CGRectMake(logoImage.frame.origin.x, 32, logoImage.frame.size.width, logoImage.frame.size.height)];
    }
	[UIView commitAnimations];
}

- (IBAction)login
{
    [appDelegate.matchlistController setIsFirstRun:NO];
	currentView = 2;

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"touchLogin"];
	
	[signupView removeFromSuperview];
	
	[signupContainer setHidden:YES];
	[loginContainer setHidden:NO];
	
	[signupBtnContainer setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.85]];
	[signupButton setAlpha:0.2];
	
	[loginBtnContainer setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.7]];
	[loginButton setAlpha:1.0];
	
	[UIView beginAnimations:@"showLogin" context:nil];
	[UIView setAnimationDuration:0.25];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    float y = [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO] - signupBtnContainer.frame.size.height - loginContainer.frame.size.height;
	[buttonContainer setFrame:CGRectMake(0, y, buttonContainer.frame.size.width, buttonContainer.frame.size.height)];
    if([UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO] < 568)
    {
        [logoImage setFrame:CGRectMake(81, 16, 158, 140)];
    }
    else
    {
        [logoImage setFrame:CGRectMake(logoImage.frame.origin.x, 32, logoImage.frame.size.width, logoImage.frame.size.height)];
    }
	[UIView commitAnimations];
}

- (IBAction)findPassword
{
    if([[UIDevice currentDevice].systemVersion floatValue] >= 5.0)
    {
        UIAlertView *prompt = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"forgotPasswordPrompt", nil)
                               message:NSLocalizedString(@"forgotPasswordTextPrompt", nil)
                               delegate:self
                               cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                               otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
        [prompt setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [prompt setTag:100];
        [prompt show];
        [prompt release];
    }
    else
    {
        UIAlertView *prompt = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"forgotPasswordPrompt", nil)
                               message:[NSString stringWithFormat:@"%@\n\n\n", NSLocalizedString(@"forgotPasswordTextPrompt", nil)]
                               delegate:self
                               cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                               otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
        UITextField *emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 98.0, 260.0, 31.0)];
        [emailTextField setBackgroundColor:[UIColor whiteColor]];
        [emailTextField setBorderStyle:UITextBorderStyleBezel];
        [emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
        [emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [emailTextField setTag:999];
        [emailTextField becomeFirstResponder];
        [prompt addSubview:emailTextField];
        [prompt setTag:100];
        [prompt show];
        [prompt release];
        [emailTextField release];
    }
}

- (void)willLogin
{
	if([emailField.text isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops"
							  message:@"You have to enter your email"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
		[emailField becomeFirstResponder];
	}
	else if(![UtilityClasses validateEmail:emailField.text])
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops"
							  message:@"Your email address is invalid"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
		[emailField becomeFirstResponder];
	}
	else if([passwordField.text isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops" 
							  message:@"Your have to enter a password"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
		[passwordField becomeFirstResponder];
	}
	else
	{
		[currentTextField resignFirstResponder];
		[appDelegate showLoading];

        NSInvocationOperation *serverOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(getDataFromServer) object:nil];
        [operationQueue addOperation:serverOperation];
        [serverOperation release];
	}
}

- (void)getDataFromServer
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

    NSString *udid = [OpenUDID value];
    NSString *currentLocale = [[NSLocale currentLocale] localeIdentifier];

    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
	[requestData setValue:udid forKey:@"udid"];
	[requestData setValue:emailField.text forKey:@"email"];
	[requestData setValue:passwordField.text forKey:@"password"];
	[requestData setValue:[NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"deviceNo"]] forKey:@"deviceNo"];
    [requestData setValue:currentLocale forKey:@"locale"];
	
	NSDictionary *apiResult = [appDelegate.apiRequest sendServerRequest:@"member" withTask:@"login" withData:requestData];
	[requestData release];
    
    if(apiResult)
    {
        NSDictionary *memberData = [apiResult valueForKey:@"memberData"];
        
        if(![apiResult valueForKey:@"error"] && [memberData valueForKey:@"memberNo"] != nil && [memberData valueForKey:@"memberNo"] != [NSNull null])
        {
            int memberNo = [[memberData valueForKey:@"memberNo"] intValue];
            if(memberNo != 0)
            {
                NSMutableDictionary *downloadRequestData = [[[NSMutableDictionary alloc] init] autorelease];
                [downloadRequestData setValue:[memberData valueForKey:@"memberNo"] forKey:@"memberNo"];
                [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 640] forKey:@"width"];
                [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 640] forKey:@"height"];
                NSData *thumbnailData = [appDelegate.apiRequest getSyncDataFromServer:@"member" withTask:@"downloadProfileImage" withData:downloadRequestData];
                
                if(thumbnailData)
                {
                    UIImage *imageData = [UIImage imageWithData:thumbnailData];
                    ProfileViewController *profileController = [[[ProfileViewController alloc] init] autorelease];
                    
                    NSInvocationOperation *saveImageOperation = [[NSInvocationOperation alloc] initWithTarget:profileController selector:@selector(saveProfileImage:) object:imageData];
                    [operationQueue addOperation:saveImageOperation];
                    [saveImageOperation release];
                }
            }
        }
        
        [self performSelectorOnMainThread:@selector(setProfileDataFromServer:) withObject:apiResult waitUntilDone:YES];
    }
	[pool drain];
}

- (void)setProfileDataFromServer:(NSDictionary *)profileData
{
	[appDelegate hideLoading];
	if([[profileData valueForKey:@"error"] intValue] == -1)
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops" 
							  message:@"Wrong password"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
	}
	else if([[profileData valueForKey:@"error"] intValue] == -2)
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops" 
							  message:@"Email doesn't exist"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
	}
	else if([profileData valueForKey:@"memberData"] != NULL)
	{
		// login successful
		NSDictionary *memberData = [profileData valueForKey:@"memberData"];
        int instanceNo = [[profileData valueForKey:@"instanceNo"] intValue];

        [appDelegate.prefs setInteger:instanceNo forKey:@"instanceNo"];
		[appDelegate.prefs setValue:emailField.text forKey:@"email"];
		[appDelegate.prefs setInteger:[[memberData valueForKey:@"memberNo"] integerValue] forKey:@"memberNo"];
		[appDelegate.prefs setValue:[memberData valueForKey:@"firstName"] forKey:@"firstName"];
		[appDelegate.prefs setValue:[memberData valueForKey:@"lastName"] forKey:@"lastName"];

        if([memberData valueForKey:@"gender"] != [NSNull null])
        {
            if([[memberData valueForKey:@"gender"] isEqualToString:@"m"])
            {
                [appDelegate.prefs setValue:@"male" forKey:@"gender"];
                [Crittercism setGender:@"m"];
            }
            else if([[memberData valueForKey:@"gender"] isEqualToString:@"f"])
            {
                [appDelegate.prefs setValue:@"female" forKey:@"gender"];
                [Crittercism setGender:@"f"];
            }
        }
		
		NSDate *birthday = nil;
		if([memberData valueForKey:@"birthday"] != [NSNull null])
		{
			NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
			[dateFormat setDateFormat:@"yyyy-MM-dd"];
			birthday = [dateFormat dateFromString:[memberData valueForKey:@"birthday"]];
			[dateFormat release];
            [Crittercism setAge:[UtilityClasses age:birthday]];
            [appDelegate.prefs setObject:birthday forKey:@"birthday"];	
		}
	
		if([memberData valueForKey:@"city"] != [NSNull null]) [appDelegate.prefs setValue:[memberData valueForKey:@"city"] forKey:@"cityName"];
		if([memberData valueForKey:@"provinceCode"] != [NSNull null]) [appDelegate.prefs setValue:[memberData valueForKey:@"provinceCode"] forKey:@"provinceCode"];
		if([memberData valueForKey:@"countryName"] != [NSNull null]) [appDelegate.prefs setValue:[memberData valueForKey:@"country"] forKey:@"countryName"];
		if([memberData valueForKey:@"countryCode"] != [NSNull null]) [appDelegate.prefs setValue:[memberData valueForKey:@"countryCode"] forKey:@"countryCode"];
        if([memberData valueForKey:@"latitude"] != [NSNull null]) [appDelegate.prefs setFloat:[[memberData valueForKey:@"latitude"] floatValue] forKey:@"latitude"];
        if([memberData valueForKey:@"longitude"] != [NSNull null]) [appDelegate.prefs setFloat:[[memberData valueForKey:@"longitude"] floatValue] forKey:@"longitude"];
		if([memberData valueForKey:@"active"] != [NSNull null]) [appDelegate.prefs setValue:[memberData valueForKey:@"active"] forKey:@"active"];
		if([memberData valueForKey:@"intro"] != [NSNull null]) [appDelegate.prefs setValue:[memberData valueForKey:@"intro"] forKey:@"intro"];
		[appDelegate.prefs synchronize];

        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"accountLogin"];
        
        // log user to Crittercism
        [Crittercism setEmail:emailField.text];
        [Crittercism setUsername:[memberData valueForKey:@"firstName"]];

        [appDelegate registerDevice];

		[appDelegate showMatchList:YES];
        [self hideOptions];
	}
}

- (void)willSignup
{
	if([firstNameField.text isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops"
							  message:@"You have to enter your first name"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
		[firstNameField becomeFirstResponder];
	}
	else if([lastNameField.text isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops"
							  message:@"You have to enter your last name"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
		[lastNameField becomeFirstResponder];
	}
	else if([emailField2.text isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops"
							  message:@"You have to enter your email"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
		[emailField2 becomeFirstResponder];
	}
	else if(![UtilityClasses validateEmail:emailField2.text])
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops"
							  message:@"Looks like an invalid email address"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
		[emailField2 becomeFirstResponder];
	}
	else if([passwordField2.text isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Oops" 
							  message:@"Your have to enter a password"
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
		[alert show];
		[alert release];
		[passwordField2 becomeFirstResponder];
	}
	else
	{
		[currentTextField resignFirstResponder];
		[appDelegate showLoading];

        NSInvocationOperation *requestSignupOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(requestSignup) object:nil];
        [operationQueue addOperation:requestSignupOperation];
        [requestSignupOperation release];
	}
}

- (void)requestSignup
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

    NSString *udid = [OpenUDID value];
    NSString *currentLocale = [[NSLocale currentLocale] localeIdentifier];

	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	[memberData setValue:[NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"deviceNo"]] forKey:@"deviceNo"];
	[memberData setValue:firstNameField.text forKey:@"firstName"];
	[memberData setValue:lastNameField.text forKey:@"lastName"];
	[memberData setValue:emailField2.text forKey:@"email"];
	[memberData setValue:passwordField2.text forKey:@"password"];
	[memberData setValue:udid forKey:@"udid"];
    [memberData setValue:currentLocale forKey:@"locale"];
    
	
	NSDictionary *apiResult = [appDelegate.apiRequest sendServerRequest:@"member" withTask:@"addMember" withData:memberData];
	[memberData release];
	
    if(apiResult)
    {
        if([[apiResult valueForKey:@"memberNo"] doubleValue] != 0)
        {
            int memberNo = [[apiResult valueForKey:@"memberNo"] intValue];
            int instanceNo = [[apiResult valueForKey:@"instanceNo"] intValue];
            [appDelegate.prefs setInteger:instanceNo forKey:@"instanceNo"];
            [appDelegate.prefs setValue:firstNameField.text forKey:@"firstName"];
            [appDelegate.prefs setValue:lastNameField.text forKey:@"lastName"];
            [appDelegate.prefs setValue:emailField2.text forKey:@"email"];
            [appDelegate.prefs setInteger:memberNo forKey:@"memberNo"];
            [appDelegate.prefs setInteger:1 forKey:@"updateMatches"];
            [appDelegate.prefs setValue:currentLocale forKey:@"currentLocale"];
            [appDelegate.prefs synchronize];
            
            [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"accountSignup"];
            
            // log user to Crittercism
            [Crittercism setEmail:emailField.text];
            [Crittercism setUsername:firstNameField.text];
            
            [appDelegate registerDevice];
            
            [self performSelectorOnMainThread:@selector(pushIntroView) withObject:nil waitUntilDone:NO];
        }
        else
        {
            NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Oops", @"title", @"Looks like you already signed up!", @"message", nil];
            [appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
            [alertContent release];
        }
        [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:YES];
    }

	[pool drain];
}

- (void)resetPassword:(NSString*)email
{
    NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	[memberData setValue:email forKey:@"email"];
    NSDictionary *result = [appDelegate.apiRequest sendServerRequest:@"member" withTask:@"resetPassword" withData:memberData];
    [memberData release];

    if(result)
    {
        if([appDelegate.networkStatus boolValue] == YES)
        {
            int updatedRows = [[result valueForKey:@"updatedRows"] intValue];
            if(updatedRows != 0)
            {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Password Reset"
                                      message:@"We've reset your password and sent it to your email"
                                      delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
                [alert show];
                [alert release];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Oops"
                                      message:@"This email doesn't seem to exist or it may be associated with a Facebook account.\nPlease check and try again."
                                      delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
                [alert show];
                [alert release];
            }
        }
    }

    [appDelegate hideLoading];
}

- (void)pushIntroView
{
	[appDelegate hideLoading];
	IntroViewController *introController = [[IntroViewController alloc] initWithNibName:@"IntroViewController" bundle:nil];
    [introController setShouldShowProfile:YES];
	[self.navigationController pushViewController:introController animated:YES];
    [self.navigationController setNavigationBarHidden:YES];
	[introController release];
}

- (bool)setProfileDataFromFacebook:(NSDictionary<FBGraphUser>*)facebookData
{
	NSString *email = [facebookData objectForKey:@"email"];;
	NSString *firstName = facebookData.first_name;
	NSString *lastName = facebookData.last_name;
	NSString *gender = [facebookData objectForKey:@"gender"];
	NSString *birthday = facebookData.birthday;
	NSString *facebookID = facebookData.id;
	id<FBGraphLocation> location = facebookData.location.location;
	
	// prepare data for server update
    NSString *udid = [OpenUDID value];
    NSString *currentLocale = [[NSLocale currentLocale] localeIdentifier];
    
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	[memberData setValue:[NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"deviceNo"]] forKey:@"deviceNo"];
	[memberData setValue:email forKey:@"email"];
	[memberData setValue:firstName forKey:@"firstName"];
	[memberData setValue:lastName forKey:@"lastName"];
	[memberData setValue:facebookID forKey:@"facebookID"];
	[memberData setValue:udid forKey:@"udid"];
    [memberData setValue:currentLocale forKey:@"locale"];
	
	// update profile data on server
	NSDictionary *apiResult = [appDelegate.apiRequest sendServerRequest:@"member" withTask:@"addMember" withData:memberData];
	[memberData release];
    
    if(apiResult)
    {
        // set prefs
        int memberNo = [[apiResult valueForKey:@"memberNo"] intValue];
        int instanceNo = [[apiResult valueForKey:@"instanceNo"] intValue];
        
        if(memberNo != 0)
        {
            [appDelegate.prefs setInteger:instanceNo forKey:@"instanceNo"];
            [appDelegate.prefs setValue:facebookID forKey:@"fbId"];
            [appDelegate.prefs setValue:email forKey:@"email"];
            [appDelegate.prefs setInteger:memberNo forKey:@"memberNo"];
            [appDelegate.prefs setValue:firstName forKey:@"firstName"];
            [appDelegate.prefs setValue:lastName forKey:@"lastName"];
            if(gender) [appDelegate.prefs setValue:gender forKey:@"gender"];
            
            hasProfileImage = NO;
            if([[apiResult valueForKey:@"profileImage"] intValue] != 0)
            {
                NSMutableDictionary *downloadRequestData = [[[NSMutableDictionary alloc] init] autorelease];
                [downloadRequestData setValue:[NSNumber numberWithInt:memberNo] forKey:@"memberNo"];
                [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 640] forKey:@"width"];
                [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 640] forKey:@"height"];
                NSData *thumbnailData = [appDelegate.apiRequest getSyncDataFromServer:@"member" withTask:@"downloadProfileImage" withData:downloadRequestData];
                
                if(thumbnailData)
                {
                    hasProfileImage = YES;
                    UIImage *imageData = [UIImage imageWithData:thumbnailData];
                    ProfileViewController *profileController = [[[ProfileViewController alloc] init] autorelease];
                    NSInvocationOperation *saveImageOperation = [[NSInvocationOperation alloc] initWithTarget:profileController selector:@selector(saveProfileImage:) object:imageData];
                    [operationQueue addOperation:saveImageOperation];
                    [saveImageOperation release];
                }
            }
            
            if([apiResult valueForKey:@"birthday"] != [NSNull null] && [apiResult valueForKey:@"birthday"] != nil)
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd"];
                NSDate *birthdayData = [formatter dateFromString:[apiResult valueForKey:@"birthday"]];
                [formatter release];
                
                [appDelegate.prefs setObject:birthdayData forKey:@"birthday"];
            }
            else if(birthday)
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"MM/dd/yyyy"];
                NSDate *birthdayData = [formatter dateFromString:birthday];
                [formatter release];
                
                [appDelegate.prefs setObject:birthdayData forKey:@"birthday"];
            }
            
            // get country data from address
            if([[apiResult valueForKey:@"latitude"] floatValue] != 0 && [[apiResult valueForKey:@"longitude"] floatValue] != 0)
            {
                [appDelegate.prefs setFloat:[[apiResult valueForKey:@"latitude"] floatValue] forKey:@"latitude"];
                [appDelegate.prefs setFloat:[[apiResult valueForKey:@"longitude"] floatValue] forKey:@"longitude"];
                
                if([apiResult valueForKey:@"city"] != [NSNull null]) [appDelegate.prefs setValue:[apiResult valueForKey:@"city"] forKey:@"cityName"];
                if([apiResult valueForKey:@"provinceCode"] != [NSNull null]) [appDelegate.prefs setValue:[apiResult valueForKey:@"provinceCode"] forKey:@"provinceCode"];
                if([apiResult valueForKey:@"country"] != [NSNull null]) [appDelegate.prefs setValue:[apiResult valueForKey:@"country"] forKey:@"countryName"];
                if([apiResult valueForKey:@"countryCode"] != [NSNull null]) [appDelegate.prefs setValue:[apiResult valueForKey:@"countryCode"] forKey:@"countryCode"];
                if([apiResult valueForKey:@"timezone"] != [NSNull null]) [appDelegate.prefs setValue:[apiResult valueForKey:@"timezone"] forKey:@"timezone"];
            }
            else if(location)
            {
                float latitude = [location.latitude floatValue];
                float longitude = [location.longitude floatValue];
                
                NSDictionary *locationData = [UtilityClasses reverseGeocode:latitude longitude:longitude sensorOn:NO];
                
                NSString *cityName = [locationData valueForKey:@"cityName"];
                NSString *provinceCode = [[locationData valueForKey:@"provinceCode"] stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
                NSString *countryName = [locationData valueForKey:@"countryName"];
                NSString *countryCode = [locationData valueForKey:@"countryCode"];
                NSString *timezone = [locationData valueForKey:@"timezone"];
                
                [appDelegate.prefs setValue:cityName forKey:@"cityName"];
                [appDelegate.prefs setValue:provinceCode forKey:@"provinceCode"];
                [appDelegate.prefs setValue:countryCode forKey:@"countryCode"];
                [appDelegate.prefs setValue:countryName forKey:@"countryName"];
                [appDelegate.prefs setValue:timezone forKey:@"timezone"];
                [appDelegate.prefs setFloat:latitude forKey:@"latitude"];
                [appDelegate.prefs setFloat:longitude forKey:@"longitude"];
            }
            
            [appDelegate.prefs setValue:currentLocale forKey:@"currentLocale"];
            if([apiResult valueForKey:@"intro"] != [NSNull null]) [appDelegate.prefs setValue:[apiResult valueForKey:@"intro"] forKey:@"intro"];
            if([apiResult valueForKey:@"active"] != [NSNull null])
            {
                [appDelegate.prefs setValue:[apiResult valueForKey:@"active"] forKey:@"active"];
                runIntro = NO;
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"facebookLogin"];
            }
            else
            {
                [appDelegate.prefs setValue:@"N" forKey:@"active"];
                runIntro = YES;
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"facebookSignup"];
            }
            
            if([apiResult valueForKey:@"newMatchAlert"]) [appDelegate.prefs setValue:[apiResult valueForKey:@"newMatchAlert"] forKey:@"newMatchAlert"];
            else if([apiResult valueForKey:@"newMissionAlert"]) [appDelegate.prefs setValue:[apiResult valueForKey:@"newMissionAlert"] forKey:@"newMissionAlert"];
            else if([apiResult valueForKey:@"newMessageAlert"]) [appDelegate.prefs setValue:[apiResult valueForKey:@"newMessageAlert"] forKey:@"newMessageAlert"];
            [appDelegate.prefs synchronize];
            
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else
    {
        return NO;
    }
}

- (IBAction)didTouchSignup
{
	[topBarTitle setText:NSLocalizedString(@"createAccountTitle", nil)];

	[UIView beginAnimations:@"showSignupView" context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];

	[topBarView setAlpha:1.0];
	[logoImage setAlpha:0];

	[buttonContainer setAlpha:0];
	[buttonContainer setFrame:CGRectMake(0, buttonContainer.frame.origin.y - signupView.frame.size.height, buttonContainer.frame.size.width, buttonContainer.frame.size.height)];
	[signupView setFrame:CGRectMake(0, 44, signupView.frame.size.width, signupView.frame.size.height+100)];

	[UIView commitAnimations];
	
	//[firstNameField becomeFirstResponder];
}

- (IBAction)didTouchFBSignup
{
    [currentTextField resignFirstResponder];
	[appDelegate openSessionWithAllowLoginUI:YES withPermissions:appDelegate.defaultPermissions];
}

- (IBAction)didCancel
{
	[currentTextField resignFirstResponder];

	if(currentView == 1 || currentView == 3)
	{
		[UIView beginAnimations:@"hideSignupView" context:nil];
		[UIView setAnimationDuration:0.6];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		
		[topBarView setAlpha:0];
		[logoImage setAlpha:1.0];
		
		[buttonContainer setAlpha:1];
		[buttonContainer setFrame:CGRectMake(0, buttonContainer.frame.origin.y + (signupView.frame.size.height-100), buttonContainer.frame.size.width, buttonContainer.frame.size.height)];
		[signupView setFrame:CGRectMake(0, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO], signupView.frame.size.width, signupView.frame.size.height-100)];
		
		[UIView commitAnimations];
	}
}

- (IBAction)didConfirm
{
	if(currentView == 1 || currentView == 3)
	{
		[self willSignup];
	}
	else if(currentView == 2)
	{
		[self willLogin];
	}
}

- (IBAction)showTerms
{
    currentView = 3;

    WebViewController *webView = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    [webView setUrl:[NSString stringWithFormat:@"http://%@/terms", apihost]];
    [webView setNavTitle:@"Terms of Use"];
    [webView setIsModalView:YES];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webView];
    [self presentModalViewController:navController animated:YES];
    [navController release];
    [webView release];
}

- (IBAction)showPolicy
{
    currentView = 3;

    WebViewController *webView = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    [webView setUrl:[NSString stringWithFormat:@"http://%@/policy", apihost]];
    [webView setNavTitle:@"Privacy Policy"];
    [webView setIsModalView:YES];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webView];
    [self presentModalViewController:navController animated:YES];
    [navController release];
    [webView release];
}

#pragma mark - UITextField delegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	currentTextField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if(currentView == 1 || currentView == 3)
	{
		if([currentTextField tag] == 11)
		{
			[lastNameField becomeFirstResponder];
		}
		else if([currentTextField tag] == 22)
		{
			[emailField2 becomeFirstResponder];
		}
		else if([currentTextField tag] == 33)
		{
			[passwordField2 becomeFirstResponder];
		}
		else if([currentTextField tag] == 44)
		{
			[self willSignup];
		}
	}
	else if(currentView == 2)
	{
		if([currentTextField tag] == 1)
		{
			[passwordField becomeFirstResponder];
		}
		else if([currentTextField tag] == 2)
		{
			[self willLogin];
		}
	}
	return NO;
}

#pragma mark - keyboard delegate
- (void) keyboardDidShow:(NSNotification *)notif
{
	// If keyboard is visible, return
	if (keyboardVisible)
	{
		return;
    }
	
	// Keyboard is now visible
	keyboardVisible = YES;
}

- (void)keyboardWillShow:(NSNotification *)notif
{
	if (keyboardVisible)
	{
		return;
    }
	
	// Get the size of the keyboard.
	CGRect keyboardBounds;
    [[notif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
	CGFloat keyboardHeight = keyboardBounds.size.height;
	
	if(currentView == 1 || currentView == 3)
	{
        [UIView beginAnimations:@"resizeScrollView" context:nil];
		[UIView setAnimationDuration:0.25];
		[signupScrollView setFrame:CGRectMake(0, 0, signupScrollView.frame.size.width, signupScrollView.frame.size.height - keyboardHeight)];
		[signupScrollView setContentSize:CGSizeMake(signupView.frame.size.width, 230)];
        [UIView commitAnimations];
	}
	else if(currentView == 2)
	{
		[topBarTitle setText:NSLocalizedString(@"loginTitle", nil)];
		
		[UIView beginAnimations:@"showLogin" context:nil];
		[UIView setAnimationDuration:0.25];
		
		[topBarView setAlpha:1.0];
		[logoImage setAlpha:0];
		
		[signupBtnContainer setAlpha:0];
		[loginButton setAlpha:0];
		[buttonContainer setFrame:CGRectMake(0, 44 - loginBtnContainer.frame.size.height, buttonContainer.frame.size.width, buttonContainer.frame.size.height+100)];
		
		[UIView commitAnimations];
	}
}

- (void)keyboardDidHide:(NSNotification *)notif
{
	// Is the keyboard already shown
	if (!keyboardVisible)
	{
		return;
	}

	// Keyboard is no longer visible
	keyboardVisible = NO;
	currentTextField = nil;
}

- (void)keyboardWillHide:(NSNotification *)notif
{
	if (!keyboardVisible)
	{
		return;
	}

	CGRect keyboardBounds;
    [[notif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
	CGFloat keyboardHeight = keyboardBounds.size.height;

	if(currentView == 1 || currentView == 3)
	{
		[signupScrollView setFrame:CGRectMake(0, signupScrollView.frame.origin.y, signupScrollView.frame.size.width, signupScrollView.frame.size.height + keyboardHeight)];
	}
	else if(currentView == 2)
	{
		[UIView beginAnimations:@"hideLogin" context:nil];
		[UIView setAnimationDuration:0.25];

		[topBarView setAlpha:0.0];
		[logoImage setAlpha:1.0];
	
		[signupBtnContainer setAlpha:1.0];
		[loginButton setAlpha:1.0];

        //[buttonContainer setFrame:CGRectMake(0, buttonContainer.frame.origin.y, buttonContainer.frame.size.width, buttonContainer.frame.size.height-100)];
		[buttonContainer setFrame:CGRectMake(0, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO] - (buttonContainer.frame.size.height-100), buttonContainer.frame.size.width, buttonContainer.frame.size.height-100)];
	}

	[UIView commitAnimations];
}

#pragma mark - facebook delegates
- (void)sessionStateChanged:(NSNotification*)notification
{
    if(FBSession.activeSession.isOpen)
    {
        [appDelegate showLoading];
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error)
         {
             if (!error)
             {
                 [self handleFacebookSession:user];
             }
         }];
    }
}

#pragma mark - facebook helpers
- (void)handleFacebookSession:(NSDictionary<FBGraphUser>*)user
{
    [appDelegate registerDevice];
    
    // set profile data
    bool confirm = [self setProfileDataFromFacebook:user];
    
    if(confirm == YES)
    {
        if(hasProfileImage == YES)
        {
            [appDelegate hideLoading];
            
            if(runIntro == YES || currentView == 1 || currentView == 3)
            {
                [self pushIntroView];
            }
            else
            {
                [appDelegate showMatchList:YES];
            }
            
            [self hideOptions];
            [appDelegate hideLoading];
        }
        else
        {
            if(appDelegate.networkStatus == NO)
            {
                [appDelegate hideLoading];
                return;
            }
            
            // get profile image
            NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/me/picture?access_token=%@&type=large", [[FBSession activeSession] accessToken]];
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2];
            
            // Run request asynchronously
            NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
            [urlConnection release];
        }
    }
    else
    {
        [appDelegate hideLoading];
        NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Oops", @"title", @"You have already created a non-Facebook account. Please login using your email address.", @"message", nil];
        [appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
        [alertContent release];
    }
}

#pragma mark - NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    UIImage *profileImage = [UIImage imageWithData:data];
    
    ProfileViewController *profileController = [[[ProfileViewController alloc] init] autorelease];
    NSInvocationOperation *saveImageOperation = [[NSInvocationOperation alloc] initWithTarget:profileController selector:@selector(saveProfileImage:) object:profileImage];
    [operationQueue addOperation:saveImageOperation];
    [saveImageOperation release];
    
    if(runIntro == YES || currentView == 1 || currentView == 3)
    {
        [self pushIntroView];
    }
    else
    {
        [appDelegate showMatchList:YES];
    }
    
    [appDelegate hideLoading];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
}

#pragma mark - alert delegate
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == 100)
    {
        if([[UIDevice currentDevice].systemVersion floatValue] < 5.0)
        {
            [currentTextField resignFirstResponder];
        }

        if(buttonIndex == 1)
        {
            UITextField *emailTextField;
            if([[UIDevice currentDevice].systemVersion floatValue] >= 5.0)
            {
                emailTextField = [actionSheet textFieldAtIndex:0];
            }
            else
            {
                emailTextField = (UITextField*)[actionSheet viewWithTag:999];
                [emailTextField resignFirstResponder];
            }
            
            NSString *emailAddress = [emailTextField text];
            
            if([emailAddress isEqualToString:@""])
            {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Oops"
                                      message:@"You must enter your email address"
                                      delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
                [alert setTag:99];
                [alert show];
                [alert release];
            }
            else if(![UtilityClasses validateEmail:emailAddress])
            {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Oops"
                                      message:@"You must enter a valid email address"
                                      delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
                [alert setTag:99];
                [alert show];
                [alert release];
            }
            else
            {
                [appDelegate showLoading];
                [self performSelector:@selector(resetPassword:) withObject:emailAddress afterDelay:0.0];
            }
        }
    }
    else if(actionSheet.tag == 99)
    {
        [self findPassword];
    }
}

@end