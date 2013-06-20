//
//  QuickMatchViewController.m
//  Wander
//
//  Created by Jiho Kang on 10/17/11.
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

#import "QuickMatchViewController.h"
#import "ConfirmQuickMatchOperation.h"
#import "DeclineQuickMatchOperation.h"
#import "MatchIntroViewController.h"

@implementation QuickMatchViewController
@synthesize matchData;
@synthesize quickMatchData;
@synthesize mapView;
@synthesize selectedAnnotationView;
@synthesize userAnnotation;
@synthesize partnerAnnotation;
@synthesize userCalloutAnnotation;
@synthesize partnerCalloutAnnotation;
@synthesize buttonContainer;
@synthesize quickMatchLabel;
@synthesize resultView;
@synthesize selectYesPrompt;
@synthesize selectNoPrompt;
@synthesize confirmNoButton;
@synthesize confirmYesButton;
@synthesize profileInfo;
@synthesize blankImageView;
@synthesize partnerImageView;
@synthesize loadThumbnailOperation;
@synthesize matchNo;
@synthesize animationPass;
@synthesize currentCoord;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];

        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
        [operationQueue setSuspended:NO];
        
        // register notifications
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(didFindQuickMatch:) name:@"didFindQuickMatch" object:nil];
        [dnc addObserver:self selector:@selector(quickMatchFailed:) name:@"quickMatchFailed" object:nil];
        [dnc addObserver:self selector:@selector(processDeclineQuickMatch:) name:@"shouldProcesshDeclineQuickMatch" object:nil];
        
        [self.navigationItem setCustomTitle:NSLocalizedString(@"quickMatchTitle", nil)];
        
        NSString *locationsPlistPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/locations.plist"];
        if([[NSFileManager defaultManager] fileExistsAtPath:locationsPlistPath])
        {
            allLocations = [[NSArray alloc] initWithContentsOfFile:locationsPlistPath];
        }
        else
        {
            allLocations = nil;
        }
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [operationQueue cancelAllOperations];
    [operationQueue release];
    [allLocations release];
    [annotationArray release];

    self.matchData = nil;
    self.quickMatchData = nil;
    self.mapView = nil;
    self.buttonContainer = nil;
    self.quickMatchLabel = nil;
    self.resultView = nil;
    self.confirmNoButton = nil;
    self.confirmYesButton = nil;
    self.profileInfo = nil;

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *backImage = [UIImage imageNamed:@"btn_back.png"];
    if(![[matchData valueForKey:@"status"] isEqualToString:@"M"])
    {
        // resize the navbar
        CGRect navBarFrame = [[self.navigationController navigationBar] frame];
        CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, 54);
        [[self.navigationController navigationBar] resizeBGLayer:newFrame];
        [[self.navigationController navigationBar] setCaption:NSLocalizedString(@"quickMatchCaption", nil)];
        [self.navigationItem.titleView setFrame:CGRectMake(0, 0, 240, 44)];

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
        // resize the navbar
        CGRect navBarFrame = [[self.navigationController navigationBar] frame];
        CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, 54);
        [[self.navigationController navigationBar] resizeBGLayer:newFrame];
        [[self.navigationController navigationBar] setCaption:NSLocalizedString(@"quickMatchCaption", nil)];
        [self.navigationItem.titleView setFrame:CGRectMake(0, 0, 320, 44)];

        [self.navigationItem setHidesBackButton:YES];
    }
    
    [confirmYesButton.layer setMasksToBounds:YES];
	[confirmYesButton.layer setCornerRadius:5.0];
	[confirmYesButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[confirmYesButton.layer setBorderWidth: 1.0];
	[confirmYesButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[confirmYesButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
	
	[confirmNoButton.layer setMasksToBounds:YES];
	[confirmNoButton.layer setCornerRadius:5.0];
	[confirmNoButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[confirmNoButton.layer setBorderWidth: 1.0];
	[confirmNoButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[confirmNoButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
    
    if(matchData != nil)
	{
        if([[matchData valueForKey:@"status"] isEqualToString:@"P"])
		{
			[self showConfirmMessage];
		}
        else
        {
            [buttonContainer setHidden:NO];
        }
	}
    
    // add pins
    annotationArray = [[NSMutableArray alloc] init];
    for(NSDictionary *location in allLocations)
    {
        float latitude = [[location valueForKey:@"latitude"] floatValue];
        float longitude = [[location valueForKey:@"longitude"] floatValue];
        CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude, longitude);
        BasicMapAnnotation *annotation = [[BasicMapAnnotation alloc] initWithLatitude:coords.latitude andLongitude:coords.longitude];
        [annotationArray addObject:annotation];
        [annotation release];
    }
    
    // disable YES/NO option
    if([[matchData valueForKey:@"status"] isEqualToString:@"M"])
    {
        [buttonContainer setHidden:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.mapView addAnnotations:annotationArray];
    
    CLLocationDegrees latitude = [appDelegate.prefs floatForKey:@"latitude"];
    CLLocationDegrees longitude = [appDelegate.prefs floatForKey:@"longitude"];
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitude);
    currentCoord = coord;
    [mapView setCenterCoordinate:coord];
    
    animationPass = 1;
    [mapView setUserInteractionEnabled:NO];
    [mapView setCenterCoordinate:coord zoomLevel:5 animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performSelector:@selector(zoomOut) withObject:nil afterDelay:1.0];
    
    // Force YES to quick match
    if([[matchData valueForKey:@"status"] isEqualToString:@"M"])
    {
        [self performSelector:@selector(didConfirmQuickMatch) withObject:nil afterDelay:1.5];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[self.navigationController navigationBar] removeCaptions];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [annotationArray release];
    self.mapView = nil;
    self.buttonContainer = nil;
    self.quickMatchLabel = nil;
    self.resultView = nil;
    self.confirmNoButton = nil;
    self.confirmYesButton = nil;
    self.profileInfo = nil;
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

- (void)zoomOut
{
    MKCoordinateSpan span = MKCoordinateSpanMake(160, 255);
    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(-30, 0), span);
    [mapView setRegion:region animated:YES];
    [mapView regionThatFits:region];
}

- (void)showConfirmMessage
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
	CGRect newResultFrame = selectYesPrompt.frame;
	newResultFrame.origin.y -= selectYesPrompt.frame.size.height;
	selectYesPrompt.frame = newResultFrame;
	
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
	CGRect newResultFrame = selectNoPrompt.frame;
	newResultFrame.origin.y -= selectNoPrompt.frame.size.height;
	selectNoPrompt.frame = newResultFrame;
    
	[UIView commitAnimations];
}

- (void)pushToIntroView
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    NSManagedObjectContext *threadContext = [ThreadMOC context];

    MatchData *_quickMatchData = (MatchData*)[threadContext objectWithID:[quickMatchData objectID]];
    [threadContext refreshObject:_quickMatchData mergeChanges:YES];

    // wait up until 5 seconds for profile image to downloaded
    if(retryCount < 50 && [_quickMatchData valueForKey:@"profileImage"] == nil)
    {
        retryCount = retryCount + 1;
        [NSThread sleepForTimeInterval:0.1];
        [self performSelectorInBackground:_cmd withObject:nil];
        [pool drain];
        return;
    }

    NSMutableArray *navStack = [[NSMutableArray alloc] init];

    // add main view to nav stack
    UIViewController *mainView = [[appDelegate.mainNavController viewControllers] objectAtIndex:0];
    [navStack addObject:mainView];
    
    // add matchlist to nav stack
    [navStack addObject:appDelegate.matchlistController];
    
    // add chat view to nav stack
    MatchIntroViewController *matchIntroController = [[MatchIntroViewController alloc] initWithNibName:@"MatchIntroViewController" bundle:nil];
    [matchIntroController setMatchData:quickMatchData];
    [navStack addObject:matchIntroController];
    [matchIntroController release];
    
    // set view controllers
    [self performSelectorOnMainThread:@selector(setNavStack:) withObject:navStack waitUntilDone:NO];
    [navStack release];

    [pool drain];
}

- (void)setNavStack:(NSArray*)stack
{
    [appDelegate hideLoading];
    [mapView setDelegate:nil];
    [appDelegate.mainNavController setViewControllers:stack animated:YES];
}

- (void)zoomIn
{
    CLLocationDegrees latitude = [[quickMatchData valueForKey:@"latitude"] floatValue];
    CLLocationDegrees longitude = [[quickMatchData valueForKey:@"longitude"] floatValue];
    CLLocationCoordinate2D partnerCoord = CLLocationCoordinate2DMake(latitude, longitude);

    shouldPushViewController = YES;

    [mapView setUserInteractionEnabled:NO];
    [mapView setCenterCoordinate:partnerCoord zoomLevel:5 animated:YES];
}

- (IBAction)didConfirmQuickMatch
{
    [appDelegate showLoading];

    retryCount = 0;
    shouldPushViewController = NO;
    ConfirmQuickMatchOperation *confirmQuickMatchOperation = [[ConfirmQuickMatchOperation alloc] init];
    [confirmQuickMatchOperation setThreadPriority:1.0];
    [operationQueue addOperation:confirmQuickMatchOperation];
    [confirmQuickMatchOperation release];

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"confirmQuickMatch"];
}

- (IBAction)didDeclineQuickMatch
{
    [appDelegate showLoading];
    DeclineQuickMatchOperation *declineQuickMatchOperation = [[DeclineQuickMatchOperation alloc] init];
    [declineQuickMatchOperation setThreadPriority:1.0];
    [operationQueue addOperation:declineQuickMatchOperation];
    [declineQuickMatchOperation release];

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"declineQuickMatch"];
}

- (IBAction)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldSetFindGuideRow" object:nil userInfo:nil];
}

- (void)didFindQuickMatch:(NSNotification *)notification
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:NO];
        return;
    }

    NSDictionary *data = [notification userInfo];
    
    // get match data
    NSManagedObjectID *newMatchObjectID = [data valueForKey:@"matchObjectID"];
    self.quickMatchData = (MatchData*)[appDelegate.mainMOC objectWithID:newMatchObjectID];
    
    [self performSelectorOnMainThread:@selector(zoomIn) withObject:nil waitUntilDone:NO];
    
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"quickMatchSuccessful"];
}

- (void)quickMatchFailed:(NSNotification *)notification
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:NO];
        return;
    }

    [self.matchData setValue:[NSNumber numberWithInt:3] forKey:@"order"];
    [self.matchData setValue:@"P" forKey:@"status"];
    [appDelegate saveContext:appDelegate.mainMOC];

    [appDelegate hideLoading];
    [self showConfirmMessage];
    
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"quickMatchFailed"];
}

- (void)processDeclineQuickMatch:(NSNotification *)notification
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:NO];
        return;
    }

    [appDelegate hideLoading];
    [self showDeclineMessage];
}

#pragma mark - map view delegates
- (void)mapView:(MKMapView *)_mapView regionDidChangeAnimated:(BOOL)animated
{
    if(animationPass == 1)
    {
        animationPass = 2;
        [_mapView setUserInteractionEnabled:YES];
    }
    
    if(shouldPushViewController == YES)
    {
        [self performSelectorInBackground:@selector(pushToIntroView) withObject:nil];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKPinAnnotationView *annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CityAnnotation"] autorelease];
    [annotationView setCanShowCallout:YES];
    [annotationView setAnimatesDrop:NO];
    
    return annotationView;
}

@end
