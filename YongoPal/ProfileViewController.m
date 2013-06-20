//
//  ProfileViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 4/13/11.
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

#import "ProfileViewController.h"
#import "UtilityClasses.h"

@implementation ProfileViewController

@synthesize CLController;
@synthesize listOfItems;
@synthesize headers;

@synthesize _tableView;
@synthesize profileImage;
@synthesize imagePlaceholder;
@synthesize nameLabel;
@synthesize genderControl;
@synthesize datePickerToolbar;
@synthesize datePicker;

@synthesize cityNameValue;
@synthesize provinceNameValue;
@synthesize provinceCodeValue;
@synthesize countryNameValue;
@synthesize countryCodeValue;
@synthesize timezoneValue;
@synthesize birthdayValue;
@synthesize introValue;
@synthesize latitude;
@synthesize longitude;

@synthesize activeField;
@synthesize firstSignup;
@synthesize isModalView;
@synthesize offset;

- (id)init
{
    self = [super init];
    if (self)
	{
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        if(operationQueue == nil)
        {
            operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:4];
            [operationQueue setSuspended:NO];
        }
        
        // register keyboard notifiers
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardDidShow:) name: UIKeyboardDidShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardDidHide:) name: UIKeyboardDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
		appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        [self.navigationItem setCustomTitle:NSLocalizedString(@"profileTitle", nil)];
        [[self.navigationController navigationBar] removeCaptions];
        
        if(operationQueue == nil)
        {
            operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:2];
            [operationQueue setSuspended:NO];
        }

        // register keyboard notifiers
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardDidShow:) name: UIKeyboardDidShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardDidHide:) name: UIKeyboardDidHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [operationQueue cancelAllOperations];
    [operationQueue release];
    [CLController release];
    [listOfItems release];
    [headers release];
    
    [_tableView release];
    [profileImage release];
    [imagePlaceholder release];
    [nameLabel release];
    [genderControl release];
    [datePickerToolbar release];
    [datePicker release];
    
    self.cityNameValue = nil;
    self.provinceNameValue = nil;
    self.provinceCodeValue = nil;
    self.countryNameValue = nil;
    self.countryCodeValue = nil;
    self.timezoneValue = nil;
    self.birthdayValue = nil;
    self.introValue = nil;

    [cityNameValue release];
    [provinceNameValue release];
    [provinceCodeValue release];
    [countryNameValue release];
    [countryCodeValue release];
    [timezoneValue release];
    [birthdayValue release];
    [introValue release];

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

    [self setProfileData];
	
	[self.profileImage.layer setMasksToBounds:YES];
	[self.profileImage.layer setCornerRadius:5.0];
	
	[self.imagePlaceholder.layer setCornerRadius:5.0];
	[self.imagePlaceholder.layer setShadowColor:[[UIColor blackColor] CGColor]];
	[self.imagePlaceholder.layer setShadowOffset:CGSizeMake(1.0f, 1.0f)];
	[self.imagePlaceholder.layer setShadowOpacity:0.7f];
	[self.imagePlaceholder.layer setShadowRadius:1.0f];

	[self._tableView setBackgroundColor:[UIColor clearColor]];
	[self._tableView setOpaque:NO];
	[self._tableView setBackgroundView:nil];
	[self._tableView setSeparatorColor:[UIColor clearColor]];
	[self._tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

	self.CLController = [[[CoreLocationController alloc] init] autorelease];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];

    self.CLController = nil;
    self.listOfItems = nil;
    self.headers = nil;
    
    self._tableView = nil;
    self.profileImage = nil;
    self.imagePlaceholder = nil;
    self.nameLabel = nil;
    self.genderControl = nil;
    self.datePickerToolbar = nil;
    self.datePicker = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.activeField = nil;
	keyboardVisible = NO;

    // if this is the first time setting up profile
	if(firstSignup == YES || isModalView == YES)
	{
		UIImage *skipImage = [UIImage imageNamed:@"btn_x.png"];
		CGRect skipFrame = CGRectMake(0, 0, skipImage.size.width, skipImage.size.height);
		CUIButton *skipButton = [[CUIButton alloc] initWithFrame:skipFrame];
		[skipButton setBackgroundImage:skipImage forState:UIControlStateNormal];
		[skipButton setShowsTouchWhenHighlighted:YES];
		[skipButton addTarget:self action:@selector(skipEditProfile) forControlEvents:UIControlEventTouchUpInside];
		UIBarButtonItem *skipBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:skipButton];
		[self.navigationItem setLeftBarButtonItem:skipBarButtonItem];
		[skipBarButtonItem release];
		[skipButton release];
		
		UIImage *doneImage = [UIImage imageNamed:@"btn_done.png"];
		CGRect doneFrame = CGRectMake(0, 0, doneImage.size.width, doneImage.size.height);
		CUIButton *doneButton = [[CUIButton alloc] initWithFrame:doneFrame];
		[doneButton setBackgroundImage:doneImage forState:UIControlStateNormal];
		[doneButton setShowsTouchWhenHighlighted:YES];
		[doneButton addTarget:self action:@selector(doneSettingProfile) forControlEvents:UIControlEventTouchUpInside];
		UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
		[self.navigationItem setRightBarButtonItem:doneBarButtonItem];
		[doneBarButtonItem release];
		[doneButton release];
		
		[appDelegate.prefs setValue:@"N" forKey:@"active"];
		[appDelegate.prefs synchronize];
	}
	else
	{
		
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
		[saveButton addTarget:self action:@selector(saveProfile) forControlEvents:UIControlEventTouchUpInside];
		UIBarButtonItem *saveBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
		[self.navigationItem setRightBarButtonItem:saveBarButtonItem];
		[saveBarButtonItem release];
		[saveButton release];
	}

	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.activeField resignFirstResponder];
	self.activeField = nil;
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

- (void)keepAlive:(NSNumber *)fromBackground
{
    if(fromBackground) [self performSelector:@selector(keepAlive:) withObject:nil afterDelay:1.0];
}

- (void)setProfileData
{
	NSString *firstName = [appDelegate.prefs valueForKey:@"firstName"];
	NSString *lastName = [appDelegate.prefs valueForKey:@"lastName"];
	NSString *gender = [appDelegate.prefs valueForKey:@"gender"];
	NSDate *birthday = [appDelegate.prefs objectForKey:@"birthday"];
	NSString *theCityName = [appDelegate.prefs valueForKey:@"cityName"];
	NSString *theProvinceName = [appDelegate.prefs valueForKey:@"provinceName"];
	NSString *theProvinceCode = [appDelegate.prefs valueForKey:@"provinceCode"];
	NSString *theCountryName = [appDelegate.prefs valueForKey:@"countryName"];
	NSString *theCountryCode = [appDelegate.prefs valueForKey:@"countryCode"];
	NSString *theTimezoneValue = [appDelegate.prefs valueForKey:@"timezone"];
	NSString *theIntro = [appDelegate.prefs valueForKey:@"intro"];
    self.latitude = [appDelegate.prefs floatForKey:@"latitude"];
    self.longitude = [appDelegate.prefs floatForKey:@"longitude"];
	
	if(![firstName isEqualToString:@""] || ![lastName isEqualToString:@""])
	{
		self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
	}

	if([gender isEqualToString:@"male"])
	{
		self.genderControl.selectedSegmentIndex = 0;
	}
	else if([gender isEqualToString:@"female"])
	{
		self.genderControl.selectedSegmentIndex = 1;
	}
	
	NSString *birthdayString = @"";
	NSString *birthdayPlaceholder = NSLocalizedString(@"monthDayYear", nil);;
	if(birthday != nil)
	{
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		self.birthdayValue = birthday;
        
        if(self.datePicker == nil) self.datePicker = [[[UIDatePicker alloc] initWithFrame:CGRectMake(0, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO], 320, 216)] autorelease];
		self.datePicker.date = birthday;

		df.dateStyle = NSDateFormatterLongStyle;
		birthdayString = [df stringFromDate:birthday];
		[df release];
	}

	NSString *locationString = @"";
	NSString *locationPlaceholder = NSLocalizedString(@"cityCountry", nil);
	if(![theCountryCode isEqualToString:@""] && theCountryCode != NULL)
	{
        if(([theProvinceCode isEqualToString:@""] || [theProvinceCode isEqualToString:theCityName]) || !theProvinceCode)
        {
            locationString = [NSString stringWithFormat:@"%@, %@", theCityName, theCountryCode];
        }
        else
        {
            locationString = [NSString stringWithFormat:@"%@(%@), %@", theCityName, theProvinceCode, theCountryCode];
        }

		self.cityNameValue = theCityName;
		self.countryNameValue = theCountryName;
		self.countryCodeValue = theCountryCode;
		self.provinceNameValue = theProvinceName;
		self.provinceCodeValue = theProvinceCode;
		self.timezoneValue = theTimezoneValue;
	}
	
	NSString *introString = @"";
	NSString *introPlaceholder = NSLocalizedString(@"iLikeTurtlesLabel", nil);
	if(theIntro != nil)
	{
		introString = theIntro;
        self.introValue = theIntro;
	}

	NSString *imagesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images"];
	NSString *imagePath = [NSBundle pathForResource:@"profileImageFull" ofType:@"jpg" inDirectory:imagesDirectory];
	if([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
	{
		UIImage *profileImageData = [UIImage imageWithContentsOfFile:imagePath];
        
        if([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
        {
            [self.profileImage setImage:[profileImageData resizedImageByScalingProportionally:CGSizeMake(160.0, 160.0)]];
        }
        else
        {
            [self.profileImage setImage:[profileImageData resizedImageByScalingProportionally:CGSizeMake(80.0, 80.0)]];
        }
	}

	// Initialize the array
	self.headers = [[[NSMutableArray alloc] init] autorelease];
	self.listOfItems = [[[NSMutableArray alloc] init] autorelease];

	[self.headers addObject:NSLocalizedString(@"whenWereYouBornLabel", nil)];
	[self.headers addObject:NSLocalizedString(@"whereDoYouLiveLabel", nil)];
	[self.headers addObject:NSLocalizedString(@"somethingAboutYouLabel", nil)];

	NSMutableDictionary *group0Dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: birthdayString, @"stringValue", birthdayPlaceholder, @"placeholder", nil];
	NSMutableDictionary *group1Dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: locationString, @"stringValue", locationPlaceholder, @"placeholder", nil];
	NSMutableDictionary *group2Dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: introString, @"stringValue", introPlaceholder, @"placeholder", nil];
	
	NSMutableArray *group0 = [[NSMutableArray alloc] initWithObjects:group0Dict, nil];
	NSMutableArray *group1 = [[NSMutableArray alloc] initWithObjects:group1Dict, nil];
	NSMutableArray *group2 = [[NSMutableArray alloc] initWithObjects:group2Dict, nil];
	
	[self.listOfItems addObject:group0];
	[self.listOfItems addObject:group1];
	[self.listOfItems addObject:group2];
	
	[group0 release];
	[group1 release];
	[group2 release];
}

- (IBAction)pickProfileImage
{
	UIActionSheet *sheet;
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		sheet = [[UIActionSheet alloc]
				 initWithTitle:nil
				 delegate:self
				 cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
				 destructiveButtonTitle:NSLocalizedString(@"deleteButton", nil)
				 otherButtonTitles:NSLocalizedString(@"takePhotoButton", nil), NSLocalizedString(@"choosePhotoButton", nil), nil];
	}
	else
	{
		sheet = [[UIActionSheet alloc]
				 initWithTitle:nil
				 delegate:self
				 cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
				 destructiveButtonTitle:NSLocalizedString(@"deleteButton", nil)
				 otherButtonTitles:NSLocalizedString(@"choosePhotoButton", nil), nil];
	}
	sheet.tag = 0;
	[sheet showInView:self.view];
	[sheet release];
}

- (void)setBirthday
{
	[_tableView setUserInteractionEnabled:NO];
	if(self.datePicker == nil) self.datePicker = [[[UIDatePicker alloc] initWithFrame:CGRectMake(0, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:NO], 320, 216)] autorelease];
    [self.datePicker setMaximumDate:[NSDate date]];
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
    [self.datePicker setHidden:NO];
	[self.datePicker addTarget:self action:@selector(changeDateInButton:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:datePicker];

	[UIView beginAnimations:@"showDatepicker" context:nil];
	[UIView setAnimationDuration:0.25];
	CGRect viewFrame = _tableView.frame;
	viewFrame.size.height -= (datePicker.frame.size.height + datePickerToolbar.frame.size.height);
	self._tableView.frame = viewFrame;

	CGRect datepickerToolbarFrame = self.datePickerToolbar.frame;
	datepickerToolbarFrame.origin.y -= (self.datePicker.frame.size.height + self.datePickerToolbar.frame.size.height);
	self.datePickerToolbar.frame = datepickerToolbarFrame;

	CGRect datepickerFrame = self.datePicker.frame;
	datepickerFrame.origin.y -= (self.datePicker.frame.size.height + self.datePickerToolbar.frame.size.height);
	self.datePicker.frame = datepickerFrame;
	[UIView commitAnimations];

	[self performSelector:@selector(scrollToRow:) withObject:[NSNumber numberWithInt:0] afterDelay:0.5];
	birthdayPickerVisible = YES;
}

- (IBAction)doneSettingBirthday
{
	if(birthdayPickerVisible == YES)
	{
		[self._tableView setUserInteractionEnabled:YES];

		CGRect viewFrame = self._tableView.frame;
		viewFrame.size.height += (self.datePicker.frame.size.height + self.datePickerToolbar.frame.size.height);
		self._tableView.frame = viewFrame;

		[UIView beginAnimations:@"hideDatepicker" context:nil];
		[UIView setAnimationDuration:0.25];

		CGRect datepickerToolbarFrame = self.datePickerToolbar.frame;
		datepickerToolbarFrame.origin.y += (self.datePicker.frame.size.height + self.datePickerToolbar.frame.size.height);
		self.datePickerToolbar.frame = datepickerToolbarFrame;

		CGRect datepickerFrame = self.datePicker.frame;
		datepickerFrame.origin.y += (self.datePicker.frame.size.height + self.datePickerToolbar.frame.size.height);
		self.datePicker.frame = datepickerFrame;
		[UIView commitAnimations];

		[self.datePicker performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.3];
	}
}

- (void)setCountry
{
	if(self.activeField != nil) [self textFieldShouldReturn:self.activeField];

	BOOL locationAllowed = [CLLocationManager locationServicesEnabled];
	
	if(locationAllowed == YES)
	{
		[self performSelector:@selector(getCurrentLocation)];
	}
	else
	{
		[self showLocationPicker];
	}
}

- (void)getCurrentLocation
{
	ProfileDataCell *cell = (ProfileDataCell *)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	[cell.spinnerContainer setHidden:NO];

	[CLController setDelegate:self];
	[CLController.locationManager startUpdatingLocation];
}

- (void)showLocationPicker
{
	LocationPickerViewController *locationPickerController = [[LocationPickerViewController alloc] initWithNibName:@"LocationPickerViewController" bundle:nil];
	[locationPickerController setDelegate:self];
	UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:locationPickerController];
	[[newNavController navigationBar] setBackgroundColor:[UIColor clearColor]];
	[self presentModalViewController:newNavController animated:YES];
	[locationPickerController release];
	[newNavController release];
}

- (void)skipEditProfile
{
	if(firstSignup == YES)
	{
		[appDelegate showMatchList:YES];
	}
	else if(isModalView == YES)
	{
		[self dismissModalViewControllerAnimated:YES];
	}
}

- (void)doneSettingProfile
{
	if(activeField != nil) [self textFieldShouldReturn:self.activeField];

	[self doneSettingBirthday];

	if([appDelegate.prefs valueForKey:@"imageIsSet"] == nil || [[appDelegate.prefs valueForKey:@"imageIsSet"] isEqualToString:@"N"])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"You need to set your photo" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert setTag:2];
		[alert show];
		[alert release];
	}
	else if(self.birthdayValue == nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"You need to set your birthday" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert setTag:4];
		[alert show];
		[alert release];
	}
	else if(self.countryCodeValue == nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"You need to set your country" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert setTag:5];
		[alert show];
		[alert release];
	}
	else if(self.introValue == nil || [self.introValue isEqualToString:@""])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"You need to write something about yourself" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert setTag:6];
		[alert show];
		[alert release];
	}
	else
	{
		NSString *gender = nil;
		
		// set gender
		if(self.genderControl.selectedSegmentIndex == 0)
		{
			gender = @"male";
            [Crittercism setGender:@"m"];
		}
		else if(self.genderControl.selectedSegmentIndex == 1)
		{
			gender = @"female";
            [Crittercism setGender:@"f"];
		}
		[appDelegate.prefs setValue:gender forKey:@"gender"];

		// set age
        [Crittercism setAge:[UtilityClasses age:birthdayValue]];
		[appDelegate.prefs setObject:birthdayValue forKey:@"birthday"];

		// set location
		[appDelegate.prefs setValue:self.cityNameValue forKey:@"cityName"];
		[appDelegate.prefs setValue:self.provinceCodeValue forKey:@"provinceCode"];
		[appDelegate.prefs setValue:self.countryCodeValue forKey:@"countryCode"];
		[appDelegate.prefs setValue:self.countryNameValue forKey:@"countryName"];
		[appDelegate.prefs setValue:self.timezoneValue forKey:@"timezone"];
        [appDelegate.prefs setFloat:self.latitude forKey:@"latitude"];
        [appDelegate.prefs setFloat:self.longitude forKey:@"longitude"];
		
		// set intro
		[appDelegate.prefs setValue:self.introValue forKey:@"intro"];

        NSInvocationOperation *uploadOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateProfileToServer) object:nil];
        [uploadOperation setThreadPriority:0.7];
        [operationQueue addOperation:uploadOperation];
        [uploadOperation release];

		// setActive
		[appDelegate.prefs setValue:@"Y" forKey:@"active"];
		[appDelegate.prefs synchronize];

		if(self.firstSignup == YES)
		{
			[appDelegate showMatchList:YES];
		}
		else if(self.isModalView == YES)
		{
			[self dismissModalViewControllerAnimated:YES];
		}
	}

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"doneSettingProfile"];
}

- (void)updateProfileToServer
{
	NSDate *birthday = [appDelegate.prefs objectForKey:@"birthday"];
	
    NSLocale *defaultLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd"];
    [formatter setLocale:defaultLocale];
	NSString *birthdayString = [formatter stringFromDate:birthday];
	[formatter release];
    [defaultLocale release];

	int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
    NSString *currentLocale = [[NSLocale currentLocale] localeIdentifier];
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	[memberData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"firstName"] forKey:@"firstName"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"lastName"] forKey:@"lastName"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"gender"] forKey:@"gender"];
	[memberData setValue:birthdayString forKey:@"birthday"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"cityName"] forKey:@"cityName"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"provinceCode"] forKey:@"provinceCode"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"countryName"] forKey:@"countryName"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"countryCode"] forKey:@"countryCode"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"timezone"] forKey:@"timezone"];
    [memberData setValue:[NSString stringWithFormat:@"%f", [appDelegate.prefs floatForKey:@"latitude"]] forKey:@"latitude"];
    [memberData setValue:[NSString stringWithFormat:@"%f", [appDelegate.prefs floatForKey:@"longitude"]] forKey:@"longitude"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"intro"] forKey:@"intro"];
    [memberData setValue:[appDelegate.prefs valueForKey:@"imageIsSet"] forKey:@"imageIsSet"];
    [memberData setValue:currentLocale forKey:@"locale"];

	NSDictionary *results = [appDelegate.apiRequest sendServerRequest:@"member" withTask:@"updateProfile" withData:memberData];
	[memberData release];

    [appDelegate.prefs setValue:currentLocale forKey:@"currentLocale"];
    if(results)
    {
        [appDelegate.prefs setValue:[results valueForKey:@"active"] forKey:@"active"];
    }
    [appDelegate.prefs synchronize];

    // run keep alive if current thread is not main thread
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:@selector(keepAlive:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
    }
}

- (void)saveProfile
{
	if(appDelegate.networkStatus == NO)
	{
		return;
	}

	if(activeField != nil) [self textFieldShouldReturn:activeField];
	[self doneSettingBirthday];
	
	// set active
	if(self.birthdayValue == nil || self.countryCodeValue == nil || self.introValue == nil || [self.introValue isEqualToString:@""] || [[appDelegate.prefs valueForKey:@"imageIsSet"] isEqualToString:@"N"] || [appDelegate.prefs valueForKey:@"imageIsSet"] == nil)
	{
		[appDelegate.prefs setValue:@"N" forKey:@"active"];
	}
	else
	{
		[appDelegate.prefs setValue:@"Y" forKey:@"active"];
	}

	// set gender
	NSString *gender = nil;
	if(self.genderControl.selectedSegmentIndex == 0)
	{
		gender = @"male";
        [Crittercism setGender:@"m"];
	}
	else if(self.genderControl.selectedSegmentIndex == 1)
	{
		gender = @"female";
        [Crittercism setGender:@"f"];
	}
	[appDelegate.prefs setValue:gender forKey:@"gender"];
	
	// set age
    [Crittercism setAge:[UtilityClasses age:birthdayValue]];
	[appDelegate.prefs setObject:self.birthdayValue forKey:@"birthday"];
	
	// set location
	[appDelegate.prefs setValue:self.cityNameValue forKey:@"cityName"];
	[appDelegate.prefs setValue:self.provinceCodeValue forKey:@"provinceCode"];
	[appDelegate.prefs setValue:self.countryCodeValue forKey:@"countryCode"];
	[appDelegate.prefs setValue:self.countryNameValue forKey:@"countryName"];
	[appDelegate.prefs setValue:self.timezoneValue forKey:@"timezone"];
    [appDelegate.prefs setFloat:self.latitude forKey:@"latitude"];
    [appDelegate.prefs setFloat:self.longitude forKey:@"longitude"];
	
	// set intro
	[appDelegate.prefs setValue:self.introValue forKey:@"intro"];
	[appDelegate.prefs synchronize];

	NSInvocationOperation *uploadOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateProfileToServer) object:nil];
    [uploadOperation setThreadPriority:0.7];
    [operationQueue addOperation:uploadOperation];
    [uploadOperation release];

	[self.navigationController popViewControllerAnimated:YES];

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"saveProfile"];
}

- (void)setLocationData
{
	ProfileDataCell *cell = [self getProfileCell:[NSNumber numberWithInt:1]];

	[cell.spinnerContainer setHidden:YES];
	NSString *location = nil;

	if([self.provinceCodeValue isEqualToString:@""] || self.provinceCodeValue == nil)
	{
		location = [NSString stringWithFormat:@"%@, %@", self.cityNameValue, self.countryCodeValue];
	}
	else
	{
		location = [NSString stringWithFormat:@"%@(%@), %@", self.cityNameValue, self.provinceCodeValue, self.countryCodeValue];
	}
	
	[cell.descriptionField setText:location];

	[[[self.listOfItems objectAtIndex:1] objectAtIndex:0] setValue:location forKey:@"stringValue"];
}

- (void)setIntro
{
	ProfileDataCell *cell = [self getProfileCell:[NSNumber numberWithInt:2]];
	[cell.descriptionField setDelegate:self];
	[cell.descriptionField setUserInteractionEnabled:YES];
	[cell.descriptionField becomeFirstResponder];
	
	[self performSelector:@selector(scrollToRow:) withObject:[NSNumber numberWithInt:2] afterDelay:0.5];
}

- (void)goBack
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)saveProfileImage:(UIImage*)image
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	if(image)
	{
		UIImage *originalImage = image;

        /* prepare upload data first */
        UIImage *fullImageJPEG = [originalImage resizedImageByScalingProportionally:CGSizeMake(640.0, 640.0)];
        NSData *jpegData = UIImageJPEGRepresentation(fullImageJPEG, 0.2);

        // write image to storage
        NSString  *pngPathFullJPEG = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images/profileImageFull.jpg"];
        [jpegData writeToFile:pngPathFullJPEG atomically:YES];

        // comfirm image is set
        [appDelegate.prefs setValue:@"Y" forKey:@"imageIsSet"];
        [appDelegate.prefs synchronize];
        
        /* upload profile image */
        NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
		int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
		NSString *memberNoString = [NSString stringWithFormat:@"%d", memberNo];
		[memberData setValue:memberNoString forKey:@"memberNo"];

		[appDelegate.apiRequest uploadImageFile:@"member" withTask:@"uploadPhoto" withImageData:jpegData withData:memberData progressDelegate:nil];
		[memberData release];

        /* save profile image to storage */
		UIImage *iconImage = [originalImage resizedImageByScalingProportionally:CGSizeMake(30.0, 30.0)];
		UIImage *iconImage2x = [originalImage resizedImageByScalingProportionally:CGSizeMake(60.0, 60.0)];
		UIImage *receivedImage = [originalImage resizedImageByScalingProportionally:CGSizeMake(75.0, 75.0)];
		UIImage *receivedImage2x = [originalImage resizedImageByScalingProportionally:CGSizeMake(150.0, 150.0)];
		UIImage *fullImage = [originalImage resizedImageByScalingProportionally:CGSizeMake(320.0, 320.0)];
		UIImage *fullImage2x = [originalImage resizedImageByScalingProportionally:CGSizeMake(640.0, 640.0)];
		
		NSString  *pngPathIcon = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images/profileImageIcon.png"];
		NSString  *pngPathIcon2x = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images/profileImageIcon@2x.png"];
		NSString  *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images/profileImage.png"];
		NSString  *pngPath2x = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images/profileImage@2x.png"];
		NSString  *pngPathFull = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images/profileImageFull.png"];
		NSString  *pngPathFull2x = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images/profileImageFull@2x.png"];
				
		[UIImagePNGRepresentation(iconImage) writeToFile:pngPathIcon atomically:YES];
		[UIImagePNGRepresentation(iconImage2x) writeToFile:pngPathIcon2x atomically:YES];
		[UIImagePNGRepresentation(receivedImage) writeToFile:pngPath atomically:YES];
		[UIImagePNGRepresentation(receivedImage2x) writeToFile:pngPath2x atomically:YES];
		[UIImagePNGRepresentation(fullImage) writeToFile:pngPathFull atomically:YES];
		[UIImagePNGRepresentation(fullImage2x) writeToFile:pngPathFull2x atomically:YES];
		
        /* notify that profile image has been saved */
		[[NSNotificationCenter defaultCenter] postNotificationName:@"profileImageDownloaded" object:self];
	}
    [pool drain];
}

- (void)deleteImage
{
	NSString *imagesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images"];
	NSString *iconPath = [NSBundle pathForResource:@"profileImageIcon" ofType:@"png" inDirectory:imagesDirectory];
	NSString *iconPath2x = [NSBundle pathForResource:@"profileImageIcon@2x" ofType:@"png" inDirectory:imagesDirectory];
	NSString *imagePath = [NSBundle pathForResource:@"profileImage" ofType:@"png" inDirectory:imagesDirectory];
	NSString *imagePath2x = [NSBundle pathForResource:@"profileImage@2x" ofType:@"png" inDirectory:imagesDirectory];
    NSString *fullJpgImagePath = [NSBundle pathForResource:@"profileImageFull" ofType:@"jpg" inDirectory:imagesDirectory];
	NSString *fullImagePath = [NSBundle pathForResource:@"profileImageFull" ofType:@"png" inDirectory:imagesDirectory];
	NSString *fullImagePath2x = [NSBundle pathForResource:@"profileImageFull@2x" ofType:@"png" inDirectory:imagesDirectory];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:iconPath error:nil];
	[fileManager removeItemAtPath:iconPath2x error:nil];
	[fileManager removeItemAtPath:imagePath error:nil];
	[fileManager removeItemAtPath:imagePath2x error:nil];
    [fileManager removeItemAtPath:fullJpgImagePath error:nil];
	[fileManager removeItemAtPath:fullImagePath error:nil];
	[fileManager removeItemAtPath:fullImagePath2x error:nil];

	[appDelegate.prefs setValue:@"N" forKey:@"active"];
    [appDelegate.prefs setValue:@"N" forKey:@"imageIsSet"];
	[appDelegate.prefs synchronize];
}

- (void)deleteImageOnServer
{
	// Prepare URL request
	int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	[memberData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];

	[appDelegate.apiRequest sendServerRequest:@"member" withTask:@"deletePhoto" withData:memberData];
	[memberData release];
}

- (void)scrollToRow:(NSNumber *)row
{
    if(self._tableView != nil)
    {
        [self._tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[row intValue]] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (ProfileDataCell *)getProfileCell:(NSNumber *)row
{
	ProfileDataCell *cell = (ProfileDataCell *)[self._tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[row intValue]]];
	return cell;
}

#pragma mark - date picker delegate
- (void)changeDateInButton:(id)sender
{
	ProfileDataCell *cell = [self getProfileCell:[NSNumber numberWithInt:0]];

	//Use NSDateFormatter to write out the date in a friendly format
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateStyle = NSDateFormatterLongStyle;
	[cell.descriptionField setText:[df stringFromDate:self.datePicker.date]];
	[df release];
	self.birthdayValue = datePicker.date;
}

#pragma mark - alert delegate
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// the user clicked one of the OK/Cancel buttons
	if(actionSheet.tag == 1)
	{
		ProfileDataCell *cell = [self getProfileCell:[NSNumber numberWithInt:1]];

		if(buttonIndex == 0)
		{
			[self showLocationPicker];
			[cell.spinnerContainer setHidden:YES];
		}
		else
		{
			[self setLocationData];
		}
	}
	
	/*
	if(actionSheet.tag == 2)
	{
		[self pickProfileImage];
	}
	
	if(actionSheet.tag == 4)
	{
		[self setBirthday];
	}
	
	if(actionSheet.tag == 5)
	{
		[self setCountry];
	}
	
	if(actionSheet.tag == 6)
	{
		ProfileDataCell *cell = [self getProfileCell:[NSNumber numberWithInt:1]];
		[cell.descriptionField becomeFirstResponder];
	}
	 */
}

#pragma mark - action sheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == 0)
	{
        NSInvocationOperation *deleteOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(deleteImage) object:nil];
        [deleteOperation setThreadPriority:0.1];
        [operationQueue addOperation:deleteOperation];
        [deleteOperation release];
    
        NSInvocationOperation *deleteOnServerOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(deleteImageOnServer) object:nil];
        [deleteOnServerOperation setThreadPriority:0.7];
        [operationQueue addOperation:deleteOnServerOperation];
        [deleteOnServerOperation release];

		[self.profileImage setImage:nil];
	}
    else if(buttonIndex == 1 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		UIImagePickerController *picker = [[UIImagePickerController alloc] init];
		[picker setDelegate:self];
        [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [picker setAllowsEditing:YES];
		[self presentModalViewController:picker animated:YES];
		[picker release];
	}
	else if(buttonIndex == 1 && ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
		UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setDelegate:self];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [picker setAllowsEditing:YES];
		[self presentModalViewController:picker animated:YES];
		[picker release];
	}
    else if(buttonIndex == 2 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setDelegate:self];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [picker setAllowsEditing:YES];
		[self presentModalViewController:picker animated:YES];
		[picker release];
    }
}

#pragma mark - image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[picker dismissModalViewControllerAnimated:YES];
    [appDelegate.prefs setValue:@"N" forKey:@"uploadSuccessful"];
    [appDelegate.prefs synchronize];
	
	UIImage *editedImage = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    
    NSInvocationOperation *saveImageOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveProfileImage:) object:editedImage];
    [saveImageOperation setThreadPriority:0.7];
    [operationQueue addOperation:saveImageOperation];
    [saveImageOperation release];

	if(editedImage)
	{
        if([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
        {
            [self.profileImage setImage:[editedImage resizedImageByScalingProportionally:CGSizeMake(160.0, 160.0)]];
        }
        else
        {
            [self.profileImage setImage:[editedImage resizedImageByScalingProportionally:CGSizeMake(80.0, 80.0)]];
        }
	}
}

#pragma mark - image picker navigation controller delegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
}

#pragma mark - location delegate
- (void)locationUpdate:(CLLocation *)location
{
	if(appDelegate.networkStatus == NO)
	{
		return;
	}

    [self.CLController setDelegate:nil];
    [CLController.locationManager stopUpdatingLocation];

	latitude = location.coordinate.latitude;
	longitude = location.coordinate.longitude;
	
	NSDictionary *locationData = [UtilityClasses reverseGeocode:latitude longitude:longitude sensorOn:YES];
	
	if([locationData count] != 0)
	{
		self.cityNameValue = [locationData valueForKey:@"cityName"];
        if([locationData valueForKey:@"provinceName"])
        {
            self.provinceNameValue = [locationData valueForKey:@"provinceName"];
            self.provinceCodeValue = [[locationData valueForKey:@"provinceCode"] stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
        }
		self.countryNameValue = [locationData valueForKey:@"countryName"];
		self.countryCodeValue = [locationData valueForKey:@"countryCode"];
		self.timezoneValue = [locationData valueForKey:@"timezone"];

		NSString *currentLocation = nil;
		if(([self.provinceNameValue isEqualToString:@""] || [self.provinceNameValue isEqualToString:cityNameValue]) || !self.provinceNameValue)
		{
			currentLocation = [NSString stringWithFormat:@"%@\n%@", self.cityNameValue, self.countryNameValue];
		}
		else
		{
			currentLocation = [NSString stringWithFormat:@"%@, %@\n%@", self.cityNameValue, self.provinceNameValue, self.countryNameValue];
		}

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"isThisYourLocationPrompt", nil) message:currentLocation delegate:self cancelButtonTitle:NSLocalizedString(@"noButton", nil) otherButtonTitles:NSLocalizedString(@"yesButton", nil), nil];
		[alert setTag:1];
		[alert show];
		[alert release];
	}
}

- (void)locationError:(NSError *)error
{
	[CLController.locationManager stopUpdatingLocation];

	LocationPickerViewController *locationPickerController = [[LocationPickerViewController alloc] initWithNibName:@"LocationPickerViewController" bundle:nil];
	[locationPickerController setDelegate:self];
	UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:locationPickerController];
	[[newNavController navigationBar] setBackgroundColor:[UIColor clearColor]];
	[self presentModalViewController:newNavController animated:YES];
	[locationPickerController release];
	[newNavController release];
	
	ProfileDataCell *cell = [self getProfileCell:[NSNumber numberWithInt:1]];
	[cell.spinnerContainer setHidden:YES];
}

#pragma mark - keyboard delegate
- (void) keyboardDidShow:(NSNotification *)notif
{
	// If keyboard is visible, return
	if (keyboardVisible)
	{
		return;
    }
	
	// Save the current location so we can restore
	// when keyboard is dismissed
	offset = _tableView.contentOffset;

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

	// Resize the scroll view to make room for the keyboard
	[UIView beginAnimations:@"resizeTable" context:nil];
	[UIView setAnimationDuration:0.25];
	CGRect viewFrame = self._tableView.frame;
	viewFrame.size.height -= keyboardHeight;
	self._tableView.frame = viewFrame;
	[UIView commitAnimations];
}

- (void)keyboardDidHide:(NSNotification *)notif
{
	// Is the keyboard already shown
	if (!keyboardVisible)
	{
		return;
	}

	// Reset the scrollview to previous location
	_tableView.contentOffset = offset;
	
	// Keyboard is no longer visible
	keyboardVisible = NO;
}

- (void)keyboardWillHide:(NSNotification *)notif
{
	if (!keyboardVisible)
	{
		return;
	}

	// Reset the frame scroll view to its original value
	[UIView beginAnimations:@"resizeTable" context:nil];
	[UIView setAnimationDuration:0.25];
	self._tableView.frame = CGRectMake(0, 0, 320, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES]);
	[UIView commitAnimations];
}

#pragma mark - text field delegate
- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
	self.activeField = textField;
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 70) ? NO : YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	ProfileDataCell *cell = [self getProfileCell:[NSNumber numberWithInt:2]];
	[cell.descriptionField setUserInteractionEnabled:NO];

	self.activeField = nil;
    if(![textField.text isEqualToString:@""])
    {
        self.introValue = textField.text;
    }
    else
    {
        self.introValue = nil;
    }
	[textField resignFirstResponder];
	return NO;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [listOfItems count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	return [[listOfItems objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ProfileCellIdentifier = @"ProfileCell";
    static NSString *LocationCellIdentifier = @"LocationCell";
    static NSString *CellIdentifier = nil;
    
    if(indexPath.section == 1)
    {
        CellIdentifier = LocationCellIdentifier;
    }
    else
    {
        CellIdentifier = ProfileCellIdentifier;
    }

	ProfileDataCell *cell = (ProfileDataCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
		NSArray *aCell = [[NSBundle mainBundle] loadNibNamed:@"ProfileDataCell" owner:nil options:nil];
		if(indexPath.section == 1)
		{
			cell = [aCell objectAtIndex:1];
		}
		else
		{
			cell = [aCell objectAtIndex:0];
		}
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectZero];
        [bgView setBackgroundColor:[UIColor clearColor]];
        [cell setBackgroundView:bgView];
        [bgView release];
        
        [cell setDelegate:self];
        [cell.buttonShadow.layer setCornerRadius:5.0];
        [cell.buttonShadow.layer setShadowColor:[[UIColor blackColor] CGColor]];
        [cell.buttonShadow.layer setShadowOffset:CGSizeMake(1.0f, 1.0f)];
        [cell.buttonShadow.layer setShadowOpacity:0.7f];
        [cell.buttonShadow.layer setShadowRadius:1.0f];
        
        [cell.textContainer.layer setMasksToBounds:YES];
        [cell.textContainer.layer setCornerRadius:5.0];
        [cell.textContainer.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
        [cell.textContainer.layer setBorderWidth: 1.0];
        
        [cell.textShadow.layer setCornerRadius:5.0];
        [cell.textShadow.layer setShadowColor:[[UIColor blackColor] CGColor]];
        [cell.textShadow.layer setShadowOffset:CGSizeMake(1.0f, 1.0f)];
        [cell.textShadow.layer setShadowOpacity:0.7f];
        [cell.textShadow.layer setShadowRadius:1.0f];
	}

	// Configure the cell...
	NSString *stringValue = [[[listOfItems objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] valueForKey:@"stringValue"];
	NSString *placeholder = [[[listOfItems objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] valueForKey:@"placeholder"];

	if(![stringValue isEqualToString:@""] || stringValue != nil) [cell.descriptionField setText:stringValue];
	[cell.descriptionField setPlaceholder:placeholder];

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	NSString *sectionName = [headers objectAtIndex:section];
	UILabel *headerTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, 280, 20)];
	[headerTitle setText:sectionName];
	
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 25)] autorelease];
    header.backgroundColor = [UIColor clearColor];
		
	headerTitle.font = [UIFont fontWithName:NSLocalizedString(@"font", nil) size:15.0f];
	headerTitle.backgroundColor = [UIColor clearColor];
	headerTitle.textColor = [UIColor blackColor];
	[header addSubview:headerTitle];
	[headerTitle release];
	
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 25;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
	
	if(activeField != nil) [self textFieldShouldReturn:activeField];

	if(indexPath.section == 0)
	{
		if(keyboardVisible == YES)
		{
			[self performSelector:@selector(setBirthday) withObject:nil afterDelay:0.5];
		}
		else
		{
			[self setBirthday];
		}
	}
	else if(indexPath.section == 1)
	{
		[self showLocationPicker];
	}
	else if(indexPath.section == 2)
	{
		[self setIntro];
	}
}

@end
