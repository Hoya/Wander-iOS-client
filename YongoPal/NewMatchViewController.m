//
//  NewMatchViewController.m
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

#import "NewMatchViewController.h"
#import "UtilityClasses.h"

@implementation NewMatchViewController
@synthesize apiRequest;
@synthesize matchNo;
@synthesize animationPass;
@synthesize currentCoord;
@synthesize matchData;
@synthesize mapView;
@synthesize mapCover;
@synthesize userAnnotationView;
@synthesize partnerAnnotationView;
@synthesize userAnnotation;
@synthesize partnerAnnotation;
@synthesize userCalloutAnnotation;
@synthesize partnerCalloutAnnotation;
@synthesize buttonContainer;
@synthesize resultView;
@synthesize selectYes;
@synthesize selectNo;
@synthesize confirmButton;
@synthesize confirmButton2;
@synthesize confirmMessage;
@synthesize profileInfo;
@synthesize blankImageView;
@synthesize partnerImageView;
@synthesize loadThumbnailOperation;
@synthesize confirmDeclineView;
@synthesize confirmDeclineDialog;
@synthesize cancelDeclineButton;
@synthesize confirmDeclineButton;
@synthesize welcomeTextLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        self.apiRequest = [[[APIRequest alloc] init] autorelease];
        [self.apiRequest setDelegate:self];
        
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:4];
        [operationQueue setSuspended:NO];
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.confirmDeclineView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.confirmDeclineDialog];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.mapCover];

    [apiRequest release];
    [operationQueue cancelAllOperations];
    [operationQueue release];
	[loadThumbnailOperation release];

	[matchData release];
    [mapView release];
    [mapCover release];
    [userAnnotationView release];
    [partnerAnnotationView release];
    [userAnnotation release];
    [partnerAnnotation release];
    [userCalloutAnnotation release];
    [partnerCalloutAnnotation release];
	[profileImage release];
	[buttonContainer release];
	[resultView release];
	[selectYes release];
	[selectNo release];
	[confirmButton release];
	[confirmButton2 release];
	[confirmMessage release];
	[profileInfo release];
    [blankImageView release];
    [partnerImageView release];
    
    [confirmDeclineView release];
    [confirmDeclineDialog release];
    [cancelDeclineButton release];
    [confirmDeclineButton release];
    [welcomeTextLabel release];

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

    [self.mapView setDelegate:self];

    [self.navigationItem setCustomTitle:NSLocalizedString(@"newMatchTitle", nil)];
    UIImage *backImage = [UIImage imageNamed:@"btn_back.png"];
    
    if(![[matchData valueForKey:@"status"] isEqualToString:@"M"])
    {
        CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
        CUIButton *backButton = [[CUIButton alloc] initWithFrame:backFrame];
        [backButton setBackgroundImage:backImage forState:UIControlStateNormal];
        [backButton setShowsTouchWhenHighlighted:YES];
        [backButton addTarget:self action:@selector(cancelMatch) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        [self.navigationItem setLeftBarButtonItem:backBarButtonItem];
        [backBarButtonItem release];
        [backButton release];
        
        shouldPlayMapAnimation = NO;
    }
    else
    {
        [self.navigationItem setHidesBackButton:YES];
        
        shouldPlayMapAnimation = YES;
    }

	[confirmButton.layer setMasksToBounds:YES];
	[confirmButton.layer setCornerRadius:5.0];
	[confirmButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[confirmButton.layer setBorderWidth: 1.0];
	[confirmButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[confirmButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
	
	[confirmButton2.layer setMasksToBounds:YES];
	[confirmButton2.layer setCornerRadius:5.0];
	[confirmButton2.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[confirmButton2.layer setBorderWidth: 1.0];
	[confirmButton2 setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[confirmButton2 setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];

    if(matchData != nil)
	{
        if([[matchData valueForKey:@"status"] isEqualToString:@"Y"])
        {
            [buttonContainer setHidden:YES];
        }
		else if([[matchData valueForKey:@"status"] isEqualToString:@"P"])
		{
			[self showConfirmMessage];
		}
		else if([[matchData valueForKey:@"status"] isEqualToString:@"N"])
		{
			[self showDeclineMessage];
		}
        else
        {
            [buttonContainer setHidden:NO];
        }
	}
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setTimeForHeader];

    timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(setTimeForHeader) userInfo:nil repeats:YES];

    // resize the navbar
	CGRect navBarFrame = [[self.navigationController navigationBar] frame];
	CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, 54);
	[[self.navigationController navigationBar] resizeBGLayer:newFrame];
    [super viewWillAppear:animated];

    NSString *welcomeText = [welcomeTextLabel text];
    NSMutableAttributedString *attrStr = [NSMutableAttributedString attributedStringWithString:welcomeText];

    [attrStr setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:15.0]];
	[attrStr setTextColor:[UIColor whiteColor]];

	[attrStr setTextBold:YES range:[attrStr.string rangeOfString:@"{partnerName}"]];
    [attrStr replaceCharactersInRange:[attrStr.string rangeOfString:@"{partnerName}"] withString:[self.matchData valueForKey:@"firstName"]];

    [attrStr setTextBold:YES range:[attrStr.string rangeOfString:@"{cityName}"]];
    [attrStr replaceCharactersInRange:[attrStr.string rangeOfString:@"{cityName}"] withString:[self.matchData valueForKey:@"cityName"]];

    self.welcomeTextLabel.attributedText = attrStr;

    if(shouldPlayMapAnimation == YES)
    {
        [self setLocations];
    }
    else
    {
        [self setPartnerLocation];
        [self showPartnerLocation];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    // zoomout map after 1 second when view did appear
    if(shouldPlayMapAnimation == YES)
    {
        animationPass = 1;
        currentCoord = CLLocationCoordinate2DMake(0, 0);
        [self performSelector:@selector(zoomMap:) withObject:[NSNumber numberWithInt:0] afterDelay:1.0];
    }

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"matchViewDidAppear"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if(timer != nil) [timer invalidate];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.confirmDeclineView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.confirmDeclineDialog];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.mapCover];

    [self.mapView setDelegate:nil];
    self.mapView = nil;
    self.mapCover = nil;
    self.userAnnotationView = nil;
    self.partnerAnnotationView = nil;
    self.userAnnotation = nil;
    self.partnerAnnotation = nil;
    self.userCalloutAnnotation = nil;
    self.partnerCalloutAnnotation = nil;

	self.buttonContainer = nil;
	self.resultView = nil;
	self.selectYes = nil;
	self.selectNo = nil;    
	self.confirmButton = nil;
	self.confirmButton2 = nil;
	self.confirmMessage = nil;
    self.profileInfo = nil;
    self.blankImageView = nil;
    self.partnerImageView = nil;
    self.loadThumbnailOperation = nil;

    self.confirmDeclineView = nil;
    self.confirmDeclineDialog = nil;
    self.cancelDeclineButton = nil;
    self.confirmDeclineButton = nil;
    self.welcomeTextLabel = nil;
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

- (void)setLocations
{
    CLLocationDegrees latitude = [appDelegate.prefs floatForKey:@"latitude"];
    CLLocationDegrees longitude = [appDelegate.prefs floatForKey:@"longitude"];
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitude);
    currentCoord = coord;
    [mapView setCenterCoordinate:coord zoomLevel:5 animated:NO];
    
    self.userAnnotation = [[[BasicMapAnnotation alloc] initWithLatitude:coord.latitude andLongitude:coord.longitude] autorelease];
    [self.mapView addAnnotation:self.userAnnotation];
    
    // get partner location coords
    CLLocationCoordinate2D partnerCoord = CLLocationCoordinate2DMake([[matchData valueForKey:@"latitude"] floatValue], [[matchData valueForKey:@"longitude"] floatValue]);
    self.partnerAnnotation = [[[BasicMapAnnotation alloc] initWithLatitude:partnerCoord.latitude andLongitude:partnerCoord.longitude] autorelease];
    [self.mapView addAnnotation:self.partnerAnnotation];
}

- (void)setPartnerLocation
{
    CLLocationCoordinate2D partnerCoord = CLLocationCoordinate2DMake([[self.matchData valueForKey:@"latitude"] floatValue], [[self.matchData valueForKey:@"longitude"] floatValue]);
    currentCoord = partnerCoord;
    [mapView setCenterCoordinate:partnerCoord];
    
    [mapView setCenterCoordinate:partnerCoord zoomLevel:5 animated:NO];

    // get partner location coords
    self.partnerAnnotation = [[[BasicMapAnnotation alloc] initWithLatitude:partnerCoord.latitude andLongitude:partnerCoord.longitude] autorelease];
	[self.mapView addAnnotation:self.partnerAnnotation];
}

- (void)showPartnerLocation
{
    [self.mapView selectAnnotation:self.partnerAnnotation animated:YES];
}

- (void)deselectAnnotationWithAnimation:(id<MKAnnotation>)annotation
{
    [mapView deselectAnnotation:annotation animated:YES];
}

- (void)zoomMap:(NSNumber*)zoomLevel
{
    [mapView setCenterCoordinate:currentCoord zoomLevel:[zoomLevel intValue] animated:YES];
}

- (void)transitionProfileImage
{
    [appDelegate.mainMOC refreshObject:matchData mergeChanges:YES];
    NSString *profileImagePath = [NSHomeDirectory() stringByAppendingPathComponent:[matchData valueForKey:@"profileImage"]];
    UIImage *profileImageFull = [UIImage imageFromFile:profileImagePath];
    
    UIImage *resizedImage = nil;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
    {
        resizedImage = [profileImageFull resizedImageByScalingProportionally:CGSizeMake(150.0, 150.0)];
    }
    else
    {
        resizedImage = [profileImageFull resizedImageByScalingProportionally:CGSizeMake(75.0, 75.0)];
    }
    [self.partnerImageView setImage:resizedImage];

    [UIView beginAnimations:@"transitionProfileImage" context:nil];
	[UIView setAnimationDuration:1.0];
    [self.blankImageView setAlpha:0];
    [UIView commitAnimations];
}

- (void)setTimeForHeader
{
    NSTimeZone *partnerTimezone = [NSTimeZone timeZoneForSecondsFromGMT:[[matchData valueForKey:@"timezoneOffset"] intValue]];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:partnerTimezone];
    [dateFormat setDefaultDate:[NSDate date]];
    NSDate *currentTime = [dateFormat defaultDate];
    [dateFormat setDateFormat:@"h:mm a"];
    NSString *currentTimeString = [dateFormat stringFromDate:currentTime];
    NSString *headerCaption = [NSString stringWithFormat:@"%@ %@", [matchData valueForKey:@"cityName"], currentTimeString];
    [dateFormat release];
    
    [[self.navigationController navigationBar] setCaption:headerCaption];
}

- (IBAction)didTouchYes
{
	if(appDelegate.networkStatus == NO)
	{
		return;
	}
    
    UIApplication *yongopalApp = [UIApplication sharedApplication];
    [appDelegate setApplicationBadgeNumber:[NSNumber numberWithInt:yongopalApp.applicationIconBadgeNumber-1]];
    [appDelegate.prefs setInteger:0 forKey:@"newMatchAlert"];
    [appDelegate.prefs synchronize];

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"confirmMatch"];

	[appDelegate showLoading];

    NSInvocationOperation *confirmOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(confirmMatch) object:nil];
    [confirmOperation setThreadPriority:1.0];
    [operationQueue addOperation:confirmOperation];
    [confirmOperation release];
}

- (void)confirmMatch
{
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    MatchData *_matchData = (MatchData*)[threadContext objectWithID:[self.matchData objectID]];

	// send confirm request to server
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
    [memberData setValue:[appDelegate.prefs valueForKey:@"firstName"] forKey:@"memberName"];
	[memberData setValue:[NSString stringWithFormat:@"%d", matchNo] forKey:@"matchNo"];
    [memberData setValue:[NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"deviceNo"]] forKey:@"deviceNo"];
	[memberData setValue:[_matchData valueForKey:@"partnerNo"] forKey:@"matchedMemberNo"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"countryCode"] forKey:@"country"];

	NSDictionary *apiResult = [self.apiRequest sendServerRequest:@"match" withTask:@"confirmMatch" withData:memberData];
	[memberData release];

    if(apiResult)
    {
        [self performSelectorOnMainThread:@selector(processResults:) withObject:apiResult waitUntilDone:NO];
    }
}

- (IBAction)didTouchNo
{
    [confirmDeclineDialog.layer setMasksToBounds:YES];
    [confirmDeclineDialog.layer setCornerRadius:8.0];
    
    [cancelDeclineButton.layer setMasksToBounds:YES];
    [cancelDeclineButton.layer setCornerRadius:5.0];
    [cancelDeclineButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
    [cancelDeclineButton.layer setBorderWidth: 1.0];
    [cancelDeclineButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
    [cancelDeclineButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
    
    [confirmDeclineButton.layer setMasksToBounds:YES];
    [confirmDeclineButton.layer setCornerRadius:5.0];
    [confirmDeclineButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
    [confirmDeclineButton.layer setBorderWidth: 1.0];
    [confirmDeclineButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
    [confirmDeclineButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];

	[confirmDeclineView setAlpha:0.0];
    
    [confirmDeclineView setHidden:NO];
    [confirmDeclineDialog setHidden:NO];
    [confirmDeclineView setFrame:self.view.bounds];
    [self.view addSubview:confirmDeclineView];
    
    [UIView beginAnimations:@"showConfirmDeclineView" context:nil];
    [UIView setAnimationDuration:0.25];
    [confirmDeclineView setAlpha:1.0];
    [UIView commitAnimations];
}

- (IBAction)cancelDecline
{
    [self hideConfirmDeclineDialog];
}

- (IBAction)confirmDecline
{
    [self hideConfirmDeclineDialog];
    if(appDelegate.networkStatus == NO)
	{
		return;
	}
    
    UIApplication *yongopalApp = [UIApplication sharedApplication];
    [appDelegate setApplicationBadgeNumber:[NSNumber numberWithInt:yongopalApp.applicationIconBadgeNumber-1]];
    [appDelegate.prefs setInteger:0 forKey:@"newMatchAlert"];
    [appDelegate.prefs synchronize];

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"declineMatch"];
    
	[appDelegate showLoading];

    NSInvocationOperation *declineOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(declineMatch) object:nil];
    [declineOperation setThreadPriority:1.0];
    [operationQueue addOperation:declineOperation];
    [declineOperation release];
}

- (void)hideConfirmDeclineDialog
{
    [UIView beginAnimations:@"hideConfirmDeclineView" context:nil];
	[UIView setAnimationDuration:0.25];
	[confirmDeclineView setAlpha:0.0];
	[UIView commitAnimations];
    
    [confirmDeclineView performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
    [confirmDeclineDialog performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
    [confirmDeclineView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
}

- (void)declineMatch
{
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    MatchData *_matchData = (MatchData*)[threadContext objectWithID:[self.matchData objectID]];

	// send decline request to server
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
	[memberData setValue:[NSString stringWithFormat:@"%d", matchNo] forKey:@"matchNo"];
	[memberData setValue:@"Y" forKey:@"wasDeclined"];
	[memberData setValue:[_matchData valueForKey:@"partnerNo"] forKey:@"matchedMemberNo"];
	NSDictionary *apiResult = [self.apiRequest sendServerRequest:@"match" withTask:@"declineMatch" withData:memberData];
	[memberData release];

    if(apiResult)
    {
        [self performSelectorOnMainThread:@selector(processResults:) withObject:apiResult waitUntilDone:NO];
    }
}

- (void)processResults:(NSDictionary*)apiResult
{
	[appDelegate hideLoading];

	// if match is successful
	if([[apiResult valueForKey:@"request"] isEqualToString:@"confirm"])
	{
		if([[apiResult valueForKey:@"matchStatus"] isEqualToString:@"Y"])
		{
			[matchData setValue:@"Y" forKey:@"status"];
			[matchData setValue:[NSNumber numberWithInt:1] forKey:@"order"];
			[appDelegate saveContext:appDelegate.mainMOC];
		}
		else
		{
			[matchData setValue:@"P" forKey:@"status"];
			[matchData setValue:[NSNumber numberWithInt:3] forKey:@"order"];
			[appDelegate saveContext:appDelegate.mainMOC];
		}
		[self showConfirmMessage];
	}
	else if([[apiResult valueForKey:@"request"] isEqualToString:@"decline"])
	{
		// delete match from core data
        [matchData setValue:@"X" forKey:@"status"];
        [matchData setValue:[NSNumber numberWithInt:5] forKey:@"order"];
        [appDelegate saveContext:appDelegate.mainMOC];
        
		[self showDeclineMessage];
	}
}

- (void)showConfirmMessage
{
	NSString *confirmMessageText = [confirmMessage text];
    NSMutableAttributedString *attrStr = [NSMutableAttributedString attributedStringWithString:confirmMessageText];
    
    [attrStr setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:15.0]];
	[attrStr setTextColor:[UIColor whiteColor]];

	[attrStr setTextBold:YES range:[attrStr.string rangeOfString:@"{partnerName}"]];
    [attrStr replaceCharactersInRange:[attrStr.string rangeOfString:@"{partnerName}"] withString:[self.matchData valueForKey:@"firstName"]];

    [attrStr setTextBold:YES range:[attrStr.string rangeOfString:@"{myLocation}"]];    
    [attrStr replaceCharactersInRange:[attrStr.string rangeOfString:@"{myLocation}"] withString:[appDelegate.prefs valueForKey:@"cityName"]];
    
    self.confirmMessage.attributedText = attrStr;

	[resultView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0]];
    [resultView setFrame:self.view.bounds];
	[self.view addSubview:resultView];
	
	[UIView beginAnimations:@"showResultView" context:nil];
	[UIView setAnimationDuration:0.25];
	
	[resultView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.3]];
	CGRect newButtonContainerFrame = buttonContainer.frame;
	newButtonContainerFrame.origin.y = [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES];
	buttonContainer.frame = newButtonContainerFrame;
	
	[UIView commitAnimations];
	
	[UIView beginAnimations:@"showResultDescription" context:nil];
	
	[UIView setAnimationDuration:0.25];
	CGRect newResultFrame = selectYes.frame;
	newResultFrame.origin.y -= selectYes.frame.size.height;
	selectYes.frame = newResultFrame;
	
	[UIView commitAnimations];
}

- (void)showDeclineMessage
{
	[resultView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0]];
    [resultView setFrame:self.view.bounds];
	[self.view addSubview:resultView];
	
	[UIView beginAnimations:@"showResultView" context:nil];
	[UIView setAnimationDuration:0.25];
	
	[resultView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.3]];
	CGRect newButtonContainerFrame = buttonContainer.frame;
	newButtonContainerFrame.origin.y = [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES];
	buttonContainer.frame = newButtonContainerFrame;
	
	[UIView commitAnimations];
	
	[UIView beginAnimations:@"showResultDescription" context:nil];
	
	[UIView setAnimationDuration:0.25];
	CGRect newResultFrame = selectNo.frame;
	newResultFrame.origin.y -= selectNo.frame.size.height;
	selectNo.frame = newResultFrame;
	
	[UIView commitAnimations];
}

- (void)cancelMatch
{
    [[self.navigationController navigationBar] removeCaptions];
    
    // resize navigation bar and table view
	CGRect navBarFrame = [[self.navigationController navigationBar] frame];
	CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, navBarFrame.size.height);
	[[self.navigationController navigationBar] resizeBGLayer:newFrame];

    [self.mapView setDelegate:nil];
    [self.navigationController popViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldSetFindGuideRow" object:nil userInfo:nil];
}

#pragma mark - MKMapView delegate
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	if(view.annotation == self.userAnnotation)
	{
		if (self.userCalloutAnnotation == nil)
		{
			self.userCalloutAnnotation = [[[CalloutMapAnnotation alloc] initWithLatitude:view.annotation.coordinate.latitude andLongitude:view.annotation.coordinate.longitude] autorelease];
		}
		else
		{
			self.userCalloutAnnotation.latitude = view.annotation.coordinate.latitude;
			self.userCalloutAnnotation.longitude = view.annotation.coordinate.longitude;
		}
		
		self.userAnnotationView = view;
		[self.mapView addAnnotation:self.userCalloutAnnotation];
	}
    else if(view.annotation == self.partnerAnnotation)
    {
        if(self.partnerCalloutAnnotation == nil)
		{
			self.partnerCalloutAnnotation = [[[CalloutMapAnnotation alloc] initWithLatitude:view.annotation.coordinate.latitude andLongitude:view.annotation.coordinate.longitude] autorelease];
		}
		else
		{
			self.partnerCalloutAnnotation.latitude = view.annotation.coordinate.latitude;
			self.partnerCalloutAnnotation.longitude = view.annotation.coordinate.longitude;
		}
		
		self.partnerAnnotationView = view;
		[self.mapView addAnnotation:self.partnerCalloutAnnotation];
    }
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if(self.userCalloutAnnotation && view.annotation == self.userAnnotation)
    {
        [self.mapView removeAnnotation:self.userCalloutAnnotation];
	}
    else if(self.partnerCalloutAnnotation && view.annotation == self.partnerAnnotation)
    {
        [self.mapView removeAnnotation:self.partnerCalloutAnnotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView *annotationView = nil;
	
    if(annotation == self.userCalloutAnnotation)
    {
        CVCustomCalloutAnnotationView *calloutMapAnnotationView = (CVCustomCalloutAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"UserCalloutAnnotation"];
		
		if (!calloutMapAnnotationView)
		{
            NSString *imagesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images"];
            NSString *imagePath = [NSBundle pathForResource:@"profileImage" ofType:@"png" inDirectory:imagesDirectory];
            
            UIImageView *profileImageView = nil;
            if(imagePath)
            {
                UIImage *profileImageData = [[UIImage alloc] initWithContentsOfFile:imagePath];
                profileImageView = [[[UIImageView alloc] initWithImage:profileImageData] autorelease];
                profileImageView.frame = CGRectMake(2, 2, profileImageView.frame.size.width, profileImageView.frame.size.height);
                [profileImageView.layer setMasksToBounds:YES];
                [profileImageView.layer setCornerRadius:5];
                [profileImageData release];
            }

			calloutMapAnnotationView = [[[CVCustomCalloutAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"UserCalloutAnnotation"] autorelease];
			[calloutMapAnnotationView.contentView addSubview:profileImageView];
		}
		
		calloutMapAnnotationView.parentAnnotationView = self.userAnnotationView;
		calloutMapAnnotationView.mapView = self.mapView;
		
		annotationView = calloutMapAnnotationView;
        
        if(self.partnerImageView.image != nil)
        {
            [self performSelector:@selector(transitionProfileImage) withObject:nil afterDelay:0.5];
        }
    }
	else if(annotation == self.partnerCalloutAnnotation)
	{
		CVCustomCalloutAnnotationView *calloutMapAnnotationView = (CVCustomCalloutAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"PartnerCalloutAnnotation"];
		
		if (!calloutMapAnnotationView)
		{
			calloutMapAnnotationView = [[[CVCustomCalloutAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"PartnerCalloutAnnotation"] autorelease];
            
            UIImage *blankImage = [UIImage imageNamed:@"blankface75"];
            self.blankImageView = [[[UIImageView alloc] initWithImage:blankImage] autorelease];
            [blankImageView setFrame:CGRectMake(2, 2, 75.0, 75.0)];
            [blankImageView setAlpha:1.0];
            
            self.partnerImageView = [[[UIImageView alloc] init] autorelease];
            [partnerImageView setFrame:CGRectMake(2, 2, 75.0, 75.0)];
            [partnerImageView.layer setMasksToBounds:YES];
            [partnerImageView.layer setCornerRadius:5];

			[calloutMapAnnotationView.contentView addSubview:self.partnerImageView];
            [calloutMapAnnotationView.contentView addSubview:self.blankImageView];
		}
		
		calloutMapAnnotationView.parentAnnotationView = self.partnerAnnotationView;
		calloutMapAnnotationView.mapView = self.mapView;
		
		annotationView = calloutMapAnnotationView;
        
        [self performSelector:@selector(transitionProfileImage) withObject:nil afterDelay:1.0];
	}
    else if (annotation == self.userAnnotation)
	{
        MKPinAnnotationView *pinAV = (MKPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"UserAnnotation"];
        if(pinAV == nil)
        {
            pinAV = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"UserAnnotation"] autorelease];
        }

		pinAV.canShowCallout = NO;
		pinAV.pinColor = MKPinAnnotationColorGreen;
        [pinAV setTag:1];
		annotationView = pinAV;
	}
	else if (annotation == self.partnerAnnotation)
	{
        MKPinAnnotationView *pinAV = (MKPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"PartnerAnnotation"];
        if(pinAV == nil)
        {
            pinAV = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"PartnerAnnotation"] autorelease];
        }

		pinAV.canShowCallout = NO;
		pinAV.pinColor = MKPinAnnotationColorRed;
        [pinAV setTag:2];
		annotationView = pinAV;
	}
	
	return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    for(id annotationView in views)
    {
        if([annotationView tag] == 1 && self.userAnnotationView.selected == NO)
        {
            [self.mapView selectAnnotation:self.userAnnotation animated:YES];
        }
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if(self.animationPass == 1)
    {
        // get partner location coords
        CLLocationCoordinate2D partnerCoord = CLLocationCoordinate2DMake([[self.matchData valueForKey:@"latitude"] floatValue], [[self.matchData valueForKey:@"longitude"] floatValue]);
        
        // zoom to partners location
        self.currentCoord = partnerCoord;
        [self performSelector:@selector(zoomMap:) withObject:[NSNumber numberWithInt:5] afterDelay:1.0];
        
        self.animationPass = 2;
    }
    else if(self.animationPass == 2)
    {
        // show partners location
        [self showPartnerLocation];
        [self.mapCover performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5];
        self.animationPass = 3;
    }
}

@end
