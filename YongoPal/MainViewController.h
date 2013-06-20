//
//  MainViewController.h
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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "YongoPalAppDelegate.h"

@interface MainViewController : UIViewController
<
	UITextFieldDelegate,
    UIAlertViewDelegate,
    NSURLConnectionDelegate
>
{
	YongoPalAppDelegate *appDelegate;
    NSOperationQueue *operationQueue;
    
	UIView *topBarView;
	UILabel *topBarTitle;
	
	UIImageView *logoImage;

	UIView *buttonContainer;
	UIView *signupBtnContainer;
	UIView *loginBtnContainer;
	UIView *signupContainer;
	UIView *loginContainer;
	UIView *loginTextContainer;

	UIButton *signupButton;
	UIButton *loginButton;
    CUIButton *forgotButton;

	UITextField *emailField;
	UITextField *passwordField;
	id currentTextField;

	UIView *signupView;
	UIScrollView *signupScrollView;
	UITextField *firstNameField;
	UITextField *lastNameField;
	UIView *nameFieldContainer;
	UITextField *emailField2;
	UIView *emailFieldContainer;
	UITextField *passwordField2;
	UIView *passwordFieldContainer;

    CUIButton *termsButton;
    CUIButton *policyButton;

    bool hasProfileImage;
	bool keyboardVisible;
	int currentView;
	bool runIntro;
}

@property (nonatomic, retain) IBOutlet UIView *topBarView;
@property (nonatomic, retain) IBOutlet UILabel *topBarTitle;
@property (nonatomic, retain) IBOutlet UIImageView *logoImage;
@property (nonatomic, retain) IBOutlet UIView *buttonContainer;
@property (nonatomic, retain) IBOutlet UIView *signupBtnContainer;
@property (nonatomic, retain) IBOutlet UIView *loginBtnContainer;
@property (nonatomic, retain) IBOutlet UIView *signupContainer;
@property (nonatomic, retain) IBOutlet UIView *loginContainer;
@property (nonatomic, retain) IBOutlet UIView *loginTextContainer;
@property (nonatomic, retain) IBOutlet UIButton *signupButton;
@property (nonatomic, retain) IBOutlet UIButton *loginButton;
@property (nonatomic, retain) IBOutlet CUIButton *forgotButton;
@property (nonatomic, retain) IBOutlet UITextField *emailField;
@property (nonatomic, retain) IBOutlet UITextField *passwordField;
@property (nonatomic, retain) IBOutlet UIView *signupView;
@property (nonatomic, retain) IBOutlet UIScrollView *signupScrollView;
@property (nonatomic, retain) IBOutlet UITextField *firstNameField;
@property (nonatomic, retain) IBOutlet UITextField *lastNameField;
@property (nonatomic, retain) IBOutlet UIView *nameFieldContainer;
@property (nonatomic, retain) IBOutlet UITextField *emailField2;
@property (nonatomic, retain) IBOutlet UIView *emailFieldContainer;
@property (nonatomic, retain) IBOutlet UITextField *passwordField2;
@property (nonatomic, retain) IBOutlet UIView *passwordFieldContainer;
@property (nonatomic, retain) IBOutlet CUIButton *termsButton;
@property (nonatomic, retain) IBOutlet CUIButton *policyButton;

- (void)registerKeyboardNotifications;
- (void)loadLoginView;
- (void)showButtons;
- (IBAction)hideOptions;
- (IBAction)signup;
- (IBAction)login;
- (IBAction)didTouchSignup;
- (IBAction)didTouchFBSignup;
- (IBAction)didCancel;
- (IBAction)didConfirm;
- (void)willLogin;
- (void)getDataFromServer;
- (void)setProfileDataFromServer:(NSDictionary *)profileData;
- (void)willSignup;
- (void)requestSignup;
- (void)resetPassword:(NSString*)email;
- (void)pushIntroView;
- (bool)setProfileDataFromFacebook:(NSDictionary<FBGraphUser>*)facebookData;
- (void)handleFacebookSession:(NSDictionary<FBGraphUser>*)user;
- (IBAction)showTerms;
- (IBAction)showPolicy;
- (IBAction)findPassword;

@end