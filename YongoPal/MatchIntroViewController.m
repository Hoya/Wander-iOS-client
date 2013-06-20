//
//  MatchIntroViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 9/2/11.
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

#import "MatchIntroViewController.h"
#import "NewChatViewController.h"

@implementation MatchIntroViewController
@synthesize matchData;
@synthesize mapView;
@synthesize profileInfoContainer;
@synthesize firstName;
@synthesize location;
@synthesize ageGender;
@synthesize intro;
@synthesize buttonContainer;
@synthesize blankImageView;
@synthesize partnerImageView;
@synthesize selectedAnnotationView;
@synthesize partnerAnnotation;
@synthesize partnerCalloutAnnotation;
@synthesize isModalView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:4];
        [operationQueue setSuspended:NO];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [operationQueue cancelAllOperations];
    [operationQueue release];
    [matchData release];
    [mapView release];
    [profileInfoContainer release];
    [firstName release];
    [location release];
    [ageGender release];
    [intro release];
    [buttonContainer release];
    [blankImageView release];
    [partnerImageView release];
    [selectedAnnotationView release];
    [partnerAnnotation release];
    [partnerCalloutAnnotation release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // back button
    [self.navigationItem setCustomTitle:NSLocalizedString(@"meetNewMatchTitle", nil)];

    if(isModalView == NO)
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
    }
    else
    {
        UIImage *backImage = [UIImage imageNamed:@"btn_done.png"];
        CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
        CUIButton *backButton = [[CUIButton alloc] initWithFrame:backFrame];
        [backButton setBackgroundImage:backImage forState:UIControlStateNormal];
        [backButton setShowsTouchWhenHighlighted:YES];
        [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        UIBarButtonItem *emptyBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease]];
        [self.navigationItem setLeftBarButtonItem:emptyBarButtonItem];
        [self.navigationItem setRightBarButtonItem:backBarButtonItem];
        [backBarButtonItem release];
        [emptyBarButtonItem release];
        [backButton release];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [operationQueue cancelAllOperations];

    self.mapView = nil;
    self.profileInfoContainer = nil;
    self.firstName = nil;
    self.location = nil;
    self.ageGender = nil;
    self.intro = nil;
    self.buttonContainer = nil;
    self.blankImageView = nil;
    self.partnerImageView = nil;
    self.selectedAnnotationView = nil;
    self.partnerAnnotation = nil;
    self.partnerCalloutAnnotation = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setTimeForHeader];
    [super viewWillAppear:animated];

    if(isModalView == YES)
    {
        [self.profileInfoContainer setFrame:CGRectMake(self.profileInfoContainer.frame.origin.x, 258, self.profileInfoContainer.frame.size.width, 158)];
        [self.mapView setFrame:CGRectMake(self.mapView.frame.origin.x, self.mapView.frame.origin.y, self.mapView.frame.size.width, 245)];
        [self.buttonContainer setHidden:YES];
    }
    else
    {
        [self.profileInfoContainer setFrame:CGRectMake(self.profileInfoContainer.frame.origin.x, 188, self.profileInfoContainer.frame.size.width, 228)];
        [self.mapView setFrame:CGRectMake(self.mapView.frame.origin.x, self.mapView.frame.origin.y, self.mapView.frame.size.width, 175)];
        [self.buttonContainer setHidden:NO];
    }

    // resize the navbar
	CGRect navBarFrame = [[self.navigationController navigationBar] frame];
	CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, 54);
    [[self.navigationController navigationBar] resizeBGLayer:newFrame];

    timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(setTimeForHeader) userInfo:nil repeats:YES];

    // setup map
    CLLocationCoordinate2D partnerCoord = CLLocationCoordinate2DMake([[self.matchData valueForKey:@"latitude"] floatValue], [[self.matchData valueForKey:@"longitude"] floatValue]);
    [self.mapView setCenterCoordinate:partnerCoord zoomLevel:5 animated:NO];
    
    UIImage *blankImage = [UIImage imageNamed:@"blankface75"];
    self.blankImageView = [[[UIImageView alloc] initWithImage:blankImage] autorelease];
    [blankImageView setFrame:CGRectMake(2, 2, 75.0, 75.0)];
    if(isModalView == YES) [self.blankImageView setAlpha:0];
    
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
    self.partnerImageView = [[[UIImageView alloc] initWithImage:resizedImage] autorelease];
    [partnerImageView setFrame:CGRectMake(2, 2, 75.0, 75.0)];
    [partnerImageView.layer setMasksToBounds:YES];
	[partnerImageView.layer setCornerRadius:5];
    
    UIView *customAnnotationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    [customAnnotationView addSubview:self.partnerImageView];
    [customAnnotationView addSubview:self.blankImageView];

    self.partnerAnnotation = [[[BasicMapAnnotation alloc] initWithLatitude:partnerCoord.latitude andLongitude:partnerCoord.longitude] autorelease];
    /*
    [partnerAnnotation setCustomView:customAnnotationView];
    [partnerAnnotation setCustomHeight:80];
    [partnerAnnotation setCustomWidth:80];
     */
	[self.mapView addAnnotation:partnerAnnotation];
    [customAnnotationView release];

    // set profile info
    [self.firstName setText:[matchData valueForKey:@"firstName"]];
    
    NSString *locationString = [NSString stringWithFormat:@"%@, %@", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"countryName"]];
    [self.location setText:locationString];
    
    NSString *age = [NSString stringWithFormat:@"%d", [UtilityClasses age:[matchData valueForKey:@"birthday"]]];
    NSString *gender = [[matchData valueForKey:@"gender"] capitalizedString];
    [self.ageGender setText:[NSString stringWithFormat:@"%@ / %@", age, gender]];
    [self.intro setText:[NSString stringWithFormat:@"\"%@\"", [matchData valueForKey:@"intro"]]];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    if(timer != nil) [timer invalidate];
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

- (void)selectAnnotation
{
    [self.mapView selectAnnotation:self.partnerAnnotation animated:YES];
}

- (void)goBack
{
    [self.mapView setDelegate:nil];
    if(isModalView == YES)
    {
        [self dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)getStarted
{
    [self.mapView setDelegate:nil];

    // disable intro view after first run
    if([[matchData valueForKey:@"shouldShowIntro"] boolValue] == YES)
    {
        [matchData setValue:[NSNumber numberWithBool:NO] forKey:@"shouldShowIntro"];
        [appDelegate saveContext:appDelegate.mainMOC];
    }

    [appDelegate showLoading];

    NSInvocationOperation *goToChatOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(goToChatScreen) object:nil];
    [goToChatOperation setThreadPriority:1.0];
    [operationQueue addOperation:goToChatOperation];
    [goToChatOperation release];
}

- (void)transitionProfileImage
{
    [UIView beginAnimations:@"transitionProfileImage" context:nil];
	[UIView setAnimationDuration:1.0];
    [self.blankImageView setAlpha:0];
    [UIView commitAnimations];
}

- (void)goToChatScreen
{
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    MatchData *_matchData = (MatchData*)[threadContext objectWithID:[self.matchData objectID]];

    NSMutableArray *navStack = [[NSMutableArray alloc] init];
    
    // add main view to nav stack
    UIViewController *mainView = [[appDelegate.mainNavController viewControllers] objectAtIndex:0];
    [navStack addObject:mainView];
    
    // add matchlist to nav stack
    [navStack addObject:appDelegate.matchlistController];
    
    // add chat view to nav stack
    NewChatViewController *newChatViewController = [[NewChatViewController alloc] initWithNibName:@"NewChatViewController" bundle:nil];
    [newChatViewController setMatchNo:[[_matchData valueForKey:@"matchNo"] intValue]];
    [newChatViewController setMatchData:matchData];
    [newChatViewController setShowIntroPrompt:YES];
    [navStack addObject:newChatViewController];
    [newChatViewController release];

    // set view controllers
    [self performSelectorOnMainThread:@selector(setNavStack:) withObject:navStack waitUntilDone:YES];
    [navStack release];
}

- (void)setNavStack:(NSArray*)stack
{
    [appDelegate hideLoading];
    [appDelegate.mainNavController setViewControllers:stack animated:YES];
}

#pragma mark - MKMapView delegate
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	if (view.annotation == self.partnerAnnotation)
	{
		if (self.partnerCalloutAnnotation == nil)
		{
			self.partnerCalloutAnnotation = [[[CalloutMapAnnotation alloc] initWithLatitude:view.annotation.coordinate.latitude andLongitude:view.annotation.coordinate.longitude] autorelease];
		}
		else
		{
			self.partnerCalloutAnnotation.latitude = view.annotation.coordinate.latitude;
			self.partnerCalloutAnnotation.longitude = view.annotation.coordinate.longitude;
		}
		
		self.selectedAnnotationView = view;
		[self.mapView addAnnotation:self.partnerCalloutAnnotation];
	}
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
	// Remove the fake bubble annotation view on deselection.
	if (self.partnerCalloutAnnotation && view.annotation == self.partnerAnnotation)
    {
        [self.mapView removeAnnotation: self.partnerCalloutAnnotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView *annotationView = nil;
	
	if (annotation == self.partnerCalloutAnnotation)
	{
		CVCustomCalloutAnnotationView *calloutMapAnnotationView = (CVCustomCalloutAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"PartnerCalloutAnnotation"];
		
		if (!calloutMapAnnotationView)
		{
			calloutMapAnnotationView = [[[CVCustomCalloutAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"PartnerCalloutAnnotation"] autorelease];
			[calloutMapAnnotationView.contentView addSubview:self.partnerImageView];
		}
		
		calloutMapAnnotationView.parentAnnotationView = self.selectedAnnotationView;
		calloutMapAnnotationView.mapView = self.mapView;
		
		annotationView = calloutMapAnnotationView;
        
        if(self.partnerImageView.image != nil)
        {
            [self performSelector:@selector(transitionProfileImage) withObject:nil afterDelay:0.5];
        }
	}
	else if (annotation == self.partnerAnnotation)
	{
		MKPinAnnotationView *pinAV = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"PartnerAnnotation"] autorelease];
		pinAV.canShowCallout = NO;
		pinAV.pinColor = MKPinAnnotationColorRed;
		annotationView = pinAV;
	}
	
	return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    [self performSelector:@selector(selectAnnotation) withObject:nil afterDelay:0.0];
}

@end
