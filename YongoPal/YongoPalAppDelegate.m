//
//  YongoPalAppDelegate.m
//  YongoPal
//
//  Created by Jiho Kang on 4/5/11.
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

#import "YongoPalAppDelegate.h"

// view controllers
#import "MainViewController.h"
#import "FeedbackViewController.h"
#import "MatchListViewController.h"
#import "ProfileViewController.h"
#import "MissionViewControllerOld.h"

// operations
#import "CountNewMessageOperation.h"

// other libs
#import "UtilityClasses.h"

// core data
#import "MatchData.h"
#import "ApiLogs.h"
#import "CrossPostLog.h"
#import "Announcements.h"

NSString *const YPSessionStateChangedNotification = @"com.yongopal.YongoPal2:YPSessionStateChangedNotification";

@implementation YongoPalAppDelegate

@synthesize apiRequest;
@synthesize prefs;
@synthesize apiHost;
@synthesize productionStage;
@synthesize bgTask;
@synthesize announcements;

@synthesize window=_window;
@synthesize tabBarController;
@synthesize mainNavController=_mainNavController;
@synthesize mainViewController=_mainViewController;
@synthesize matchlistController=_matchlistController;
@synthesize loadingView;
@synthesize matchEndAlertView;
@synthesize matchEndAlertPrompt;
@synthesize matchEndConfirmButton;
@synthesize migrationView;
@synthesize migrationProgressLabel;
@synthesize migrationProgressView;
@synthesize migrationSpinner;
@synthesize overlayWindow;

@synthesize defaultPermissions;

@synthesize networkStatus;
@synthesize wifiStatus;
@synthesize hostStatus;

@synthesize shouldUpdateMatchList;
@synthesize networkingCount;

@synthesize managedObjectContext=__managedObjectContext;
@synthesize managedObjectModel=__managedObjectModel;
@synthesize persistentStoreCoordinator=__persistentStoreCoordinator;

+ (YongoPalAppDelegate *)sharedAppDelegate
{
	return (YongoPalAppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark - application runtime
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // start Crittercism
    [Crittercism enableWithAppID:critterAppId];

    loading = NO;
	self.prefs = [NSUserDefaults standardUserDefaults];
    if([self.prefs integerForKey:@"matchLimit"] == 0)
    {
        [self.prefs setInteger:1 forKey:@"matchLimit"];
    }
    if([self.prefs integerForKey:@"maxMatchCount"] == 0)
    {
        [self.prefs setInteger:2 forKey:@"maxMatchCount"];
    }
    if([self.prefs valueForKey:@"quickMatchEnabled"] == nil)
    {
        [self.prefs setValue:@"Y" forKey:@"quickMatchEnabled"];
    }
    if([self.prefs valueForKey:@"suspended"] == nil)
    {
        [self.prefs setValue:@"N" forKey:@"suspended"];
    }
    [self.prefs synchronize];
    self.apiRequest = [APIRequest sharedAPIRequest];
    [self.apiRequest setDelegate:self];

    operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:1];

	// set default api host
	self.apiHost = apihost;
    self.productionStage = development;
	
	// start reachability
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [self startReachability];
    
    // start facebook
    self.defaultPermissions = [[[NSMutableArray alloc] initWithObjects:@"user_about_me", @"email", @"user_birthday", @"user_interests", @"user_location", nil] autorelease];
    [self openSessionWithAllowLoginUI:NO withPermissions:nil];

	// create image directory
	NSFileManager *fileManager= [NSFileManager defaultManager]; 
	NSString *imagesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images"];
	BOOL isDir;
	if(![fileManager fileExistsAtPath:imagesDirectory isDirectory:&isDir])
	{
		if(![fileManager createDirectoryAtPath:imagesDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
		{
            if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"Error: Create folder failed %@", imagesDirectory);
            }
		}
	}

	NSString *videosDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Videos"];
	if(![fileManager fileExistsAtPath:videosDirectory isDirectory:&isDir])
	{
		if(![fileManager createDirectoryAtPath:videosDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
		{
            if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"Error: Create folder failed %@", videosDirectory);
            }
		}
	}

	// set init notification perfs
	if([self.prefs valueForKey:@"newMatchAlert"] == nil)
	{
		[self.prefs setValue:@"Y" forKey:@"newMatchAlert"];
	}
    
    if([self.prefs valueForKey:@"newMissionAlert"] == nil)
	{
		[self.prefs setValue:@"Y" forKey:@"newMissionAlert"];
	}

	if([self.prefs valueForKey:@"newMessageAlert"] == nil)
	{
		[self.prefs setValue:@"Y" forKey:@"newMessageAlert"];
	}
    [self.prefs synchronize];

    // load main view controller
    [self mainNavController];
	[self.mainNavController.view setAlpha:0.0];
	[[self.mainNavController navigationBar] setBackgroundColor:[UIColor clearColor]];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	[self.window setRootViewController:self.mainNavController];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];

    // activate window
    [self.window makeKeyAndVisible];

	// migrate data and load the main view
    launchAppQueue = [[NSOperationQueue alloc] init];
    [launchAppQueue setMaxConcurrentOperationCount:1];

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    NSInvocationOperation *launchAppOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(launchAppWithOptions:) object:launchOptions];
    [launchAppOperation setThreadPriority:1.0];
    [launchAppQueue addOperation:launchAppOperation];
    [launchAppOperation release];
    
    // Localytics
    [[LocalyticsSession sharedLocalyticsSession] startSession:localyticsApiKey];

    // Wander API Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldConfirmCrossPost:) name:@"shouldConfirmCrossPost" object:nil];

    self.overlayWindow = [[[StatusBarOverlayWindow alloc] initWithFrame:CGRectZero] autorelease];
    /*
    UIViewController *emptyViewController = [[[UIViewController alloc] init] autorelease];
    [emptyViewController.view setBackgroundColor:[UIColor clearColor]];
    [emptyViewController.view setHidden:YES];
    [self.overlayWindow setRootViewController:emptyViewController];
    */
    [self.overlayWindow setBackgroundColor:[UIColor clearColor]];
    [self.overlayWindow setHidden:NO];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */

	// save data
	[self.prefs synchronize];
	[self saveContext:self.managedObjectContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */

    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];

    [self.prefs synchronize];
	[self saveContext:self.managedObjectContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
    
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // always in debug mode for beta builds
    #if !RELEASE || TARGET_IPHONE_SIMULATOR
    [self.prefs setValue:@"Y" forKey:@"debugMode"];
    [self.prefs synchronize];
    #endif
    
    // init crittercism
    if([self.prefs valueForKey:@"firstName"]) [Crittercism setUsername:[self.prefs valueForKey:@"firstName"]];
    if([self.prefs valueForKey:@"email"]) [Crittercism setEmail:[self.prefs valueForKey:@"email"]];
    if([self.prefs objectForKey:@"birthday"]) [Crittercism setAge:[UtilityClasses age:[self.prefs objectForKey:@"birthday"]]];
    if([self.prefs objectForKey:@"gender"])
	{
		if([[self.prefs objectForKey:@"gender"] isEqualToString:@"male"])
		{
            [Crittercism setGender:@"m"];
		}
		else 
		{
            [Crittercism setGender:@"f"];
		}
	}

    // register for remote notifications
	if([self.prefs integerForKey:@"memberNo"] != 0)
	{
        [self registerDevice];
	}

    // update views
    NSInvocationOperation *updateViewsOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateViews) object:nil];
    [updateViewsOperation setThreadPriority:0.1];
    [launchAppQueue addOperation:updateViewsOperation];
    [updateViewsOperation release];
    
    // update member location if needed
    if([self.prefs floatForKey:@"latitude"] == 0 && [self.prefs floatForKey:@"longitude"] == 0)
    {
        NSInvocationOperation *updateLocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateMemberLocation) object:nil];
        [updateLocationOperation setThreadPriority:0.0];
        [launchAppQueue addOperation:updateLocationOperation];
        [updateLocationOperation release];
    }

    // update timeozne is needed
    NSInvocationOperation *updateLocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateTimezoneData) object:nil];
    [updateLocationOperation setThreadPriority:0.0];
    [launchAppQueue addOperation:updateLocationOperation];
    [updateLocationOperation release];
    
    // update announcements
    NSInvocationOperation *updateAnnouncementsOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateAnnouncements) object:nil];
    [updateAnnouncementsOperation setThreadPriority:0.0];
    [launchAppQueue addOperation:updateAnnouncementsOperation];
    [updateAnnouncementsOperation release];

    // this means the user switched back to this app without completing a login in Safari/Facebook App
    if (FBSession.activeSession.state == FBSessionStateCreatedOpening)
    {
        // BUG: for the iOS 6 preview we comment this line out to compensate for a race-condition in our
        // state transition handling for integrated Facebook Login; production code should close a
        // session in the opening state on transition back to the application; this line will again be
        // active in the next production rev
        [FBSession.activeSession close]; // so we close our session and start over
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Saves changes in the application's managed object context before the application terminates.

    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];

    [FBSession.activeSession close];

	[self.prefs synchronize];
	[self saveContext:self.managedObjectContext];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // We need to handle URLs by passing them to FBSession in order for SSO authentication
    // to work.
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration
{
    [self.overlayWindow shouldRotateOverlay:newStatusBarOrientation];
}

- (void)application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)newStatusBarFrame
{
    [self.overlayWindow setFrame:newStatusBarFrame];
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.loadingView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.matchEndAlertView];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.apiRequest setDelegate:nil];
    self.apiRequest = nil;
    self.prefs = nil;
    self.apiHost = nil;
    self.productionStage = nil;
    self.announcements = nil;

    [operationQueue cancelAllOperations];
    [operationQueue release];
    
    [launchAppQueue cancelAllOperations];
    [launchAppQueue release];

    self.window = nil;
    self.mainNavController = nil;
    self.mainViewController = nil;
	self.matchlistController = nil;
    self.loadingView = nil;
    self.matchEndAlertPrompt = nil;
    self.matchEndConfirmButton = nil;
    self.matchEndConfirmButton = nil;
    self.migrationView = nil;
    self.migrationProgressLabel = nil;
    self.migrationProgressView = nil;
    self.migrationSpinner = nil;
    self.overlayWindow = nil;

	self.defaultPermissions = nil;

    [self stopReachability];
    [internetReach release];
    [wifiReach release];
    [hostReach release];
    self.networkStatus = nil;
    self.wifiStatus = nil;
    self.hostStatus = nil;

    [__managedObjectContext release];
	[__managedObjectModel release];
	[__persistentStoreCoordinator release];

    [super dealloc];
}

- (void)awakeFromNib
{
    /*
     Typically you should set up the Core Data stack here, usually by passing the managed object context to the first view controller.
     self.<#View controller#>.managedObjectContext = self.managedObjectContext;
    */
}

- (void)launchAppWithOptions:(NSDictionary *)launchOptions
{
    // reset all data if member number is 0
    if([self.prefs integerForKey:@"memberNo"] == 0)
    {
        [self performSelectorOnMainThread:@selector(resetAllData) withObject:nil waitUntilDone:YES];
    }

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"YongoPal.sqlite"];

    // perform core data migrations if necessary
    [migrationView setFrame:self.window.bounds];
    [self.migrationView performSelectorOnMainThread:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
    [self.window performSelectorOnMainThread:@selector(addSubview:) withObject:self.migrationView waitUntilDone:YES];
    if(![self progressivelyMigrateURL:storeURL ofType:NSSQLiteStoreType toModel:self.managedObjectModel])
    {
        NSString *debugMode = [self.prefs valueForKey:@"debugMode"];
        [self.prefs setValue:@"N" forKey:@"debugMode"];
        [self.prefs synchronize];

        // get new instance since the entire database is about to be reset
        NSMutableDictionary *deviceData = [[NSMutableDictionary alloc] init];
        NSString *deviceUdid = [OpenUDID value];
        [deviceData setValue:deviceUdid forKey:@"udid"];
        NSDictionary *apiResults = [self.apiRequest sendServerRequest:@"member" withTask:@"registerNewInstance" withData:deviceData];
        [deviceData release];
        
        if(apiResults)
        {
            if([apiResults valueForKey:@"instanceNo"] != nil && [apiResults valueForKey:@"instanceNo"] != [NSNull null])
            {
                // reset the persistent store one new instance has been created
                NSString *documentDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:[NSBundle pathForResource:@"YongoPal" ofType:@"sqlite" inDirectory:documentDir] error:&error];
                
                // remove migration view
                [self.migrationView performSelectorOnMainThread:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
                [self.migrationView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
                self.migrationView = nil;
                self.migrationProgressLabel = nil;
                self.migrationProgressView = nil;
                self.migrationSpinner = nil;
                
                int instanceNo = [[apiResults valueForKey:@"instanceNo"] intValue];
                [self.prefs setInteger:instanceNo forKey:@"instanceNo"];
                [self.prefs setValue:debugMode forKey:@"debugMode"];
                [self.prefs synchronize];
            }
            else
            {
                NSDictionary *alertData = [[NSDictionary alloc] initWithObjectsAndKeys:@"Oops", @"title", @"Sorry, Wander failed to connect to our servers. Please check your network connection and try again later.", @"message", nil];
                [self performSelectorOnMainThread:@selector(displayFatalAlert:) withObject:alertData waitUntilDone:NO];
                [alertData release];
                return;
            }
        }
    }
    
    // load the main view first
    [self performSelectorOnMainThread:@selector(loadMainView) withObject:nil waitUntilDone:YES];

    // run if launched by remote notification
    NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(remoteNotif)
    {
        [self performSelectorOnMainThread:@selector(launchNotification:) withObject:remoteNotif waitUntilDone:YES];
    }
}

- (void)updateViews
{
    id currentView = [self.mainNavController topViewController];
    
    bool userIsActive = NO;
    if([[self.prefs valueForKey:@"active"] isEqualToString:@"Y"]) userIsActive = YES;
    
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    // update match list
    if(userIsActive == YES && [currentView respondsToSelector:@selector(updateMatchListData)])
    {
        //[currentView performSelectorOnMainThread:@selector(updateMatchListData) withObject:nil waitUntilDone:NO];
    }

    // get match session data
    NSArray *currentSessions = [self.matchlistController currentSessions:threadContext];
    if([currentSessions count] > 0)
    {
        [self performSelectorOnMainThread:@selector(showEndMatchAlert) withObject:nil waitUntilDone:NO];
    }

    // get feedback list
    FeedbackViewController *feedbackController = [[FeedbackViewController alloc] init];
    [feedbackController performSelectorOnMainThread:@selector(updateFeedbackList) withObject:nil waitUntilDone:NO];
    [feedbackController release];

    // try to resume profile image upload if previous upload failed
    [self performSelectorOnMainThread:@selector(resumeProfileImageUpload) withObject:nil waitUntilDone:NO];

    NSOperationQueue *threadOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
    [threadOperationQueue setMaxConcurrentOperationCount:1];

    // try to resume cross posting syncronization to server
    NSInvocationOperation *resumeCrosspostOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(resumeCrosspostLogSync) object:nil];
    [resumeCrosspostOperation setThreadPriority:0.1];
    [threadOperationQueue addOperation:resumeCrosspostOperation];
    [resumeCrosspostOperation release];
    
    // update locale
    NSInvocationOperation *updateLocaleOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateMemberLocale) object:nil];
    [updateLocaleOperation setThreadPriority:0.0];
    [threadOperationQueue addOperation:updateLocaleOperation];
    [updateLocaleOperation release];
    
    // check for new messages
    if([currentView respondsToSelector:@selector(updateNewMessageAlerts)])
    {
        [currentView performSelectorOnMainThread:@selector(updateNewMessageAlerts) withObject:nil waitUntilDone:NO];
    }

    // update chat view
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldCheckNewMessages" object:nil];
    
    // update missions button
    if([currentView respondsToSelector:@selector(setMissionsButton)])
    {
        [currentView performSelectorOnMainThread:@selector(setMissionsButton) withObject:nil waitUntilDone:NO];
    }
}

- (void)resetAllData
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cancelAllAsyncOperations" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"willLogout" object:nil];

    // logout facebook
    if(FBSession.activeSession.isOpen)
    {
        [FBSession.activeSession closeAndClearTokenInformation];
    }

    [self setApplicationBadgeNumber:[NSNumber numberWithInt:0]];
    
    // clear user prefs
    [self performSelectorInBackground:@selector(clearUserPrefs) withObject:nil];
    
	// delete result controller cache
	[NSFetchedResultsController deleteCacheWithName:nil];
	
	// clear core data
	[self clearCoreData];
    
    // unregister device
    [self performSelectorInBackground:@selector(unregisterDevice) withObject:nil];
    
    // delete all image files
    [self performSelectorInBackground:@selector(deleteAllImageFiles) withObject:nil];
    
    // reset the match list controller
    self.matchlistController = nil;
}

- (void)clearUserPrefs
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // delete all prefs
	int deviceNo = [self.prefs integerForKey:@"deviceNo"];
	[self.prefs removeObjectForKey:@"memberNo"];
	NSDictionary *defaultsDict = [self.prefs dictionaryRepresentation];
	for(NSString *key in [defaultsDict allKeys])
	{
		[self.prefs removeObjectForKey:key];
	}
	[NSUserDefaults resetStandardUserDefaults];
    
	self.prefs = [NSUserDefaults standardUserDefaults];
	[self.prefs setInteger:deviceNo forKey:@"deviceNo"];
	[self.prefs setValue:@"Y" forKey:@"newMatchAlert"];
    [self.prefs setValue:@"Y" forKey:@"newMissionAlert"];
	[self.prefs setValue:@"Y" forKey:@"newMessageAlert"];
    [self.prefs setInteger:1 forKey:@"matchLimit"];
    [self.prefs setInteger:2 forKey:@"maxMatchCount"];
	[self.prefs synchronize];
    
    [pool release];
}

- (void)deleteAllImageFiles
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // delete images
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *imagesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images"];
	NSError *error = nil;
	for (NSString *file in [fm contentsOfDirectoryAtPath:imagesDirectory error:&error])
	{
		BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", imagesDirectory, file] error:&error];
		if (!success || error)
		{
            if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"failed to delete file: %@", error);
            }
		}
	}
    
    [pool release];
}

- (void)updateTimezoneData
{
    CLLocationDegrees latitude = [self.prefs floatForKey:@"latitude"];
    CLLocationDegrees longitude = [self.prefs floatForKey:@"longitude"];

    if(latitude != 0 && longitude != 0)
    {
        NSError *error;
        // get timezone
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/timezone/json?location=%f,%f&timestamp=%f&sensor=false",latitude, longitude, timestamp]]];
        NSData *response = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:&error];
        [self didStopNetworking];

        SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
        NSString *json_string = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSDictionary *apiResult = [jsonParser objectWithString:json_string error:nil];
        NSString *timeZoneId = [apiResult valueForKey:@"timeZoneId"];
        NSString *currentTimezoneString = [self.prefs valueForKey:@"timezone"];

        if(![currentTimezoneString isEqualToString:timeZoneId])
        {
            int memberNo = [self.prefs integerForKey:@"memberNo"];
            NSMutableDictionary *memberData = [NSMutableDictionary dictionary];
            [memberData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
            [memberData setValue:timeZoneId forKey:@"timezone"];
            NSDictionary *apiResults = [self.apiRequest sendServerRequest:@"member" withTask:@"updateTimezone" withData:memberData];
            
            if(apiResults)
            {
                if([apiResults valueForKey:@"profileUpdated"] != [NSNull null])
                {
                    [self.prefs setValue:timeZoneId forKey:@"timezone"];
                    [self.prefs synchronize];
                }
            }
        }

        [json_string release];
        [jsonParser release];
    }
}

- (void)updateAnnouncements
{
    int memberNo = [self.prefs integerForKey:@"memberNo"];
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
    NSDictionary *apiResults = [self.apiRequest sendServerRequest:@"member" withTask:@"getAnnouncements" withData:requestData];
    
    if(apiResults)
    {
        NSArray *announcementList = [apiResults valueForKey:@"announcements"];
        NSManagedObjectContext *threadContext = [ThreadMOC context];
        if([announcementList count] > 0)
        {
            NSFetchRequest *announcementRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Announcements" inManagedObjectContext:threadContext];
            [announcementRequest setEntity:entity];
            [announcementRequest setReturnsObjectsAsFaults:YES];
            
            for(NSDictionary *announcementData in announcementList)
            {
                int announcementNo = [[announcementData valueForKey:@"announcementNo"] intValue];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"announcementNo = %d", announcementNo];
                [announcementRequest setPredicate:predicate];
                if([threadContext countForFetchRequest:announcementRequest error:nil] == 0)
                {
                    Announcements *announcement = (Announcements*)[NSEntityDescription insertNewObjectForEntityForName:@"Announcements" inManagedObjectContext:threadContext];
                    [announcement setAnnouncementNo:[NSNumber numberWithInt:announcementNo]];
                    [announcement setUserChecked:[NSNumber numberWithBool:NO]];
                }
                [self saveContext:threadContext];
            }
            [announcementRequest release];
        }
        
        NSFetchRequest *announcementRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Announcements" inManagedObjectContext:threadContext];
        [announcementRequest setEntity:entity];
        [announcementRequest setReturnsObjectsAsFaults:YES];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userChecked = NO"];
        [announcementRequest setPredicate:predicate];
        
        self.announcements = [NSMutableArray arrayWithArray:[threadContext executeFetchRequest:announcementRequest error:nil]];
        [announcementRequest release];
        
        if([self.announcements count] > 0)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedAnnouncement" object:nil userInfo:nil];
        }
    }
    [requestData release];
}

#pragma mark - getters and setters
- (MainViewController *)mainViewController
{
    if(_mainViewController == nil)
    {
        _mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    }
    return _mainViewController;
}

- (void)setMainViewController:(MainViewController *)mainViewController
{
    [mainViewController retain];
    [_mainViewController release];
    _mainViewController = mainViewController;
}

- (UINavigationController *)mainNavController
{
    if(_mainNavController == nil)
    {
        _mainNavController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
    }
    return _mainNavController;
}

- (void)setMainNavController:(UINavigationController *)mainNavController
{
    [mainNavController retain];
    [_mainNavController release];
    _mainNavController = mainNavController;
}

- (MatchListViewController *)matchlistController
{
    if(_matchlistController == nil)
    {
        _matchlistController = [[MatchListViewController alloc] initWithNibName:@"MatchListViewController" bundle:nil];
    }
    return _matchlistController;
}

- (void)setMatchlistController:(MatchListViewController *)matchlistController
{
    [matchlistController retain];
    [_matchlistController release];
    _matchlistController = matchlistController;
}

#pragma mark - Wander API helpers
- (void)updateMemberLocation
{
    NSString *locationString = nil;
    if([self.prefs valueForKey:@"cityName"] || ![[self.prefs valueForKey:@"cityName"] isEqualToString:@""])
    {
        if([[self.prefs valueForKey:@"provinceCode"] isEqualToString:@""] || [self.prefs valueForKey:@"provinceCode"] == nil)
        {
            locationString = [NSString stringWithFormat:@"%@,%@", [self.prefs valueForKey:@"cityName"], [self.prefs valueForKey:@"countryName"]];
        }
        else
        {
            locationString = [NSString stringWithFormat:@"%@,%@,%@", [self.prefs valueForKey:@"cityName"], [self.prefs valueForKey:@"provinceCode"], [self.prefs valueForKey:@"countryName"]];
        }
        CLLocationCoordinate2D coords = [UtilityClasses geocode:locationString];
        
        [self.prefs setFloat:coords.latitude forKey:@"latitude"];
        [self.prefs setFloat:coords.longitude forKey:@"longitude"];
        [self.prefs synchronize];
    }
}

- (void)shouldConfirmCrossPost:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:NO];
        return;
    }

    NSMutableDictionary *userData = [NSMutableDictionary dictionaryWithDictionary:[noif userInfo]];

    if(![userData valueForKey:@"logObject"])
    {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"CrossPostLog" inManagedObjectContext:self.managedObjectContext];
        [request setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key = %@", [userData valueForKey:@"key"]];
        [request setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedResults = [self.managedObjectContext executeFetchRequest:request error:&error];
        int logCount = [fetchedResults count];
        [request release];
        
        if(error != nil)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        if(logCount == 0)
        {
            NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"CrossPostLog" inManagedObjectContext:self.managedObjectContext];
            [newManagedObject setValue:[userData valueForKey:@"key"] forKey:@"key"];
            [newManagedObject setValue:[userData valueForKey:@"postType"] forKey:@"type"];
            [newManagedObject setValue:[NSNumber numberWithBool:NO] forKey:@"didSync"];
            [newManagedObject setValue:[UtilityClasses currentUTCDate] forKey:@"regDatetime"];
            [self saveContext:self.managedObjectContext];
            
            int matchLimit = [self.prefs integerForKey:@"matchLimit"];
            int maxMatchCount = [self.prefs integerForKey:@"maxMatchCount"];
            
            if(matchLimit < maxMatchCount)
            {
                int crossPostedPhotoCount = [self.prefs integerForKey:@"crossPostedPhotoCount"];
                [self.prefs setInteger:crossPostedPhotoCount+1 forKey:@"crossPostedPhotoCount"];
                if(crossPostedPhotoCount+1 == 3)
                {
                    [self.matchlistController setShouldReloadTableData:YES];
                    [self.prefs setBool:NO forKey:@"didShowExtraGuideAlertView"];
                }
                [self.prefs synchronize];
            }
            
            [userData setValue:newManagedObject forKey:@"logObject"];
        }
        else
        {
            [userData setValue:[fetchedResults objectAtIndex:0] forKey:@"logObject"];
        }
    }

    [self performSelectorInBackground:@selector(confirmCrossPost:) withObject:userData];
}

- (void)confirmCrossPost:(NSDictionary*)userData
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    int memberNo = [self.prefs integerForKey:@"memberNo"];
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
    [requestData setValue:[userData valueForKey:@"key"] forKey:@"key"];
    [requestData setValue:[userData valueForKey:@"postType"] forKey:@"postType"];
    NSDictionary *results = [self.apiRequest sendServerRequest:@"chat" withTask:@"confirmCrossPost" withData:requestData];
    [requestData release];

    if(results)
    {
        if([results count] > 0)
        {
            NSManagedObjectContext *threadContext = [ThreadMOC context];
            
            CrossPostLog *log = (CrossPostLog*)[threadContext objectWithID:[[userData valueForKey:@"logObject"] objectID]];
            [log setValue:[NSNumber numberWithBool:YES] forKey:@"didSync"];
            [self saveContext:threadContext];
        }
    }
    
    [pool release];
}

- (void)setApplicationBadgeNumber:(NSNumber*)badge
{
    int badgeCount = [badge intValue];
    if(badgeCount < 0) badgeCount = 0;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeCount];
}

- (void)resumeProfileImageUpload
{
    // resume upload of profile image
    if([[self.prefs valueForKey:@"imageIsSet"] isEqualToString:@"Y"] && [[self.prefs valueForKey:@"uploadSuccessful"] isEqualToString:@"N"])
    {
        NSString *imagesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images"];
        NSString *imagePath = [NSBundle pathForResource:@"profileImageFull" ofType:@"jpg" inDirectory:imagesDirectory];
        
        if(imagePath)
        {
            UIImage *imageData = [UIImage imageWithContentsOfFile:imagePath];
            ProfileViewController *profileController = [[[ProfileViewController alloc] init] autorelease];
            [profileController performSelectorInBackground:@selector(saveProfileImage:) withObject:imageData];
        }
        else
        {
            [self.prefs setValue:@"N" forKey:@"imageIsSet"];
            [self.prefs synchronize];
        }
    }
}

- (void)resumeCrosspostLogSync
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CrossPostLog" inManagedObjectContext:threadContext];
    [request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"didSync = NO"];
	[request setPredicate:predicate];
	
	NSError *error = nil;
    NSArray *fetchedResults = [threadContext executeFetchRequest:request error:&error];
    if([fetchedResults count] > 0)
    {
        for(CrossPostLog *log in fetchedResults)
        {
            if([log valueForKey:@"key"] != nil && [log valueForKey:@"type"] != nil)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldConfirmCrossPost" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[log valueForKey:@"key"], @"key", [log valueForKey:@"type"], @"postType", log, @"logObject", nil]];
            }
            else
            {
                [threadContext deleteObject:log];
                [self saveContext:threadContext];
            }
        }
    }
	[request release];
    
    [pool release];
}

- (void)updateMemberLocale
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    if([self.prefs integerForKey:@"memberNo"] != 0)
    {
        // set device locale
        NSString *currentLocale = [[NSLocale currentLocale] localeIdentifier];
        if(![[self.prefs valueForKey:@"currentLocale"] isEqualToString:currentLocale])
        {
            NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
            NSString *memberNoString = [NSString stringWithFormat:@"%d", [self.prefs integerForKey:@"memberNo"]];
            NSString *currentLocale = [[NSLocale currentLocale] localeIdentifier];
            [memberData setValue:memberNoString forKey:@"memberNo"];
            [memberData setValue:currentLocale forKey:@"locale"];
            
            NSDictionary *apiResults = [self.apiRequest sendServerRequest:@"member" withTask:@"updateMemberLocale" withData:memberData];
            [memberData release];
            
            if(apiResults)
            {
                if([apiResults valueForKey:@"updatedRows"] != [NSNull null])
                {
                    [self.prefs setValue:currentLocale forKey:@"currentLocale"];
                    [self.prefs synchronize];
                }
            }
        }
    }
    [pool drain];
}

#pragma mark - Remote Notification
// Retrieve the device token
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    #if !TARGET_IPHONE_SIMULATOR
    NSOperationQueue *threadOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
    [threadOperationQueue setMaxConcurrentOperationCount:1];

    NSInvocationOperation *confirmPushOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(confirmPushNotifications:) object:devToken];
    [confirmPushOperation setThreadPriority:0.0];
    [threadOperationQueue addOperation:confirmPushOperation];
    [confirmPushOperation release];
    #endif
}

// Provide a user explanation for when the registration fails
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error 
{
    [self.prefs removeObjectForKey:@"rntypes"];
    [self.prefs synchronize];
}

// Handle an actual notification
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSInvocationOperation *noifOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(launchNotification:) object:userInfo];
    [noifOperation setThreadPriority:0.0];
    [launchAppQueue addOperation:noifOperation];
    [noifOperation release];
}

#pragma mark - Application's Documents directory
/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - navigation
- (void)popToMatchList
{
    if(![[self.mainNavController topViewController] respondsToSelector:@selector(getMatch)])
    {
        [self.mainNavController popToViewController:self.matchlistController animated:NO];
    }
}

- (void)setNavStack:(NSArray*)navStack
{
    [self.mainNavController setViewControllers:navStack animated:NO];
}

#pragma mark - apn helpers
- (void)registerDevice
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
        return;
    }

	NSUInteger types = (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound);    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
}

- (void)unregisterDevice
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

	// remove push alerts
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [self.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
	[self.apiRequest sendServerRequest:@"member" withTask:@"logout" withData:memberData];
	[memberData release];

	[[UIApplication sharedApplication] performSelectorOnMainThread:@selector(unregisterForRemoteNotifications) withObject:nil waitUntilDone:NO];
    
    [self.prefs removeObjectForKey:@"rntypes"];
    [self.prefs synchronize];

    [pool release];
}

- (void)confirmPushNotifications:(NSData *)devToken
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    if([self.prefs integerForKey:@"memberNo"] != 0)
	{
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        // Check what Notifications the user has turned on
        NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        
        // Set the defaults to disabled unless we find otherwise...
        NSString *pushBadge = (rntypes & UIRemoteNotificationTypeBadge) ? @"enabled" : @"disabled";
        NSString *pushAlert = (rntypes & UIRemoteNotificationTypeAlert) ? @"enabled" : @"disabled";
        NSString *pushSound = (rntypes & UIRemoteNotificationTypeSound) ? @"enabled" : @"disabled";
        
        [self.prefs setInteger:rntypes forKey:@"rntypes"];
        [self.prefs synchronize];
        
        // Get the users Device Model, Display Name, Unique ID, Token & Version Number
        UIDevice *dev = [UIDevice currentDevice];
        NSString *deviceUdid = [OpenUDID value];
        NSString *deviceName = [dev.name stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
        NSString *deviceModel = [dev.model stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
        NSString *deviceVersion = dev.systemVersion;
        
        // Prepare the Device Token for Registration (remove spaces and < >)
        NSString *deviceToken = [[[[devToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString: @" " withString: @""];
        
        NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
        NSString *memberNoString = [NSString stringWithFormat:@"%d", [self.prefs integerForKey:@"memberNo"]];
        [requestData setValue:memberNoString forKey:@"memberNo"];
        [requestData setValue:appName forKey:@"appName"];
        [requestData setValue:appVersion forKey:@"appVersion"];
        [requestData setValue:pushBadge forKey:@"pushBadge"];
        [requestData setValue:pushAlert forKey:@"pushAlert"];
        [requestData setValue:pushSound forKey:@"pushSound"];
        [requestData setValue:deviceUdid forKey:@"deviceUdid"];
        [requestData setValue:deviceName forKey:@"deviceName"];
        [requestData setValue:deviceModel forKey:@"deviceModel"];
        [requestData setValue:deviceVersion forKey:@"deviceVersion"];
        [requestData setValue:deviceToken forKey:@"deviceToken"];
        
        NSDictionary *results = [self.apiRequest sendServerRequest:@"member" withTask:@"registerDevice" withData:requestData];
        [requestData release];
        
        if(results)
        {
            if([results valueForKey:@"deviceNo"] != [NSNull null])
            {
                int deviceNo = [[results valueForKey:@"deviceNo"] intValue];
                [self.prefs setInteger:deviceNo forKey:@"deviceNo"];
                if([results valueForKey:@"debug"] != [NSNull null])
                {
                    [self.prefs setValue:[results valueForKey:@"debug"] forKey:@"debugMode"];
                }
                
#if !RELEASE || TARGET_IPHONE_SIMULATOR
                [self.prefs setValue:@"Y" forKey:@"debugMode"];
#endif
                
                if([results valueForKey:@"badgeCount"] != [NSNull null])
                {
                    int badgeCount = [[results valueForKey:@"badgeCount"] intValue];
                    [self performSelectorOnMainThread:@selector(setApplicationBadgeNumber:) withObject:[NSNumber numberWithInt:badgeCount] waitUntilDone:NO];
                }
                
                if([results valueForKey:@"newMatchAlert"] != [NSNull null])
                {
                    int newMatchAlert = [[results valueForKey:@"newMatchAlert"] intValue];
                    [self.prefs setInteger:newMatchAlert forKey:@"newMatchAlert"];
                }
                
                if([results valueForKey:@"matchSuccessfulAlert"] != [NSNull null])
                {
                    int matchSuccessfulAlert = [[results valueForKey:@"matchSuccessfulAlert"] intValue];
                    [self.prefs setInteger:matchSuccessfulAlert forKey:@"matchSuccessfulAlert"];
                }
                
                if([results valueForKey:@"newMessageAlert"] != [NSNull null])
                {
                    int newMessageAlert = [[results valueForKey:@"newMessageAlert"] intValue];
                    [self.prefs setInteger:newMessageAlert forKey:@"newMessageAlert"];
                }
                
                if([results valueForKey:@"newMissionAlert"] != [NSNull null])
                {
                    int newMissionAlert = [[results valueForKey:@"newMissionAlert"] intValue];
                    [self.prefs setInteger:newMissionAlert forKey:@"newMissionAlert"];
                }
                
                if([results valueForKey:@"active"] != [NSNull null])
                {
                    if([[results valueForKey:@"active"] isEqualToString:@"H"])
                    {
                        [self.prefs setValue:@"Y" forKey:@"suspended"];
                    }
                    else
                    {
                        [self.prefs setValue:@"N" forKey:@"suspended"];
                        [self.prefs setValue:[results valueForKey:@"active"] forKey:@"active"];
                    }
                }
                
                if([results valueForKey:@"quickMatchEnabled"] != [NSNull null])
                {
                    [self.prefs setValue:[results valueForKey:@"quickMatchEnabled"] forKey:@"quickMatchEnabled"];
                }
                
                if([results valueForKey:@"matchLimit"] != [NSNull null])
                {
                    int matchLimit = [[results valueForKey:@"matchLimit"] intValue];
                    [self.prefs setInteger:matchLimit forKey:@"matchLimit"];
                }
                
                if([results valueForKey:@"maxMatchCount"] != [NSNull null])
                {
                    int maxMatchCount = [[results valueForKey:@"maxMatchCount"] intValue];
                    [self.prefs setInteger:maxMatchCount forKey:@"maxMatchCount"];
                }
                [self.prefs synchronize];
            }
        }
        }
    [pool drain];
}

- (bool)pushStatus
{
	return [[UIApplication sharedApplication] enabledRemoteNotificationTypes] ? YES : NO;
}

// Report the notification payload when launched by alert
- (void)launchNotification:(NSDictionary *)userInfo
{
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    UIApplication *application = [UIApplication sharedApplication];

    // get application state
	UIApplicationState state = [application applicationState];
    
    // get alert type from notification
	int alertType = [[userInfo valueForKey:@"type"] intValue];
	
    // get match number from notification
	NSNumber *matchNo = [NSNumber numberWithInt:0];
	if([userInfo valueForKey:@"matchNo"]) matchNo = [NSNumber numberWithInt:[[userInfo objectForKey:@"matchNo"] intValue]];

	// set badge
	NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
    [self performSelectorOnMainThread:@selector(setApplicationBadgeNumber:) withObject:[NSNumber numberWithInt:[[apsInfo objectForKey:@"badge"] intValue]] waitUntilDone:YES];

    // get current view
    id currentView = [self.mainNavController topViewController];
    
    // new match notification
	if(alertType == 1)
	{
        [self.prefs setInteger:1 forKey:@"newMatchAlert"];
        [self.prefs synchronize];

        // pop to match list
        // clear invalid matches
        [self.matchlistController performSelectorOnMainThread:@selector(clearInvalidMatches) withObject:nil waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(popToMatchList) withObject:nil waitUntilDone:YES];

		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:threadContext];
		[request setEntity:entity];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo = %d", [matchNo intValue]]];
		[request setPredicate:predicate];

		NSError *error = nil;
		NSArray *fetchedObjects = [threadContext executeFetchRequest:request error:&error];
		[request release];

        if([fetchedObjects count] == 0 || [matchNo intValue] == 0)
        {
            if(currentView && [currentView respondsToSelector:@selector(getMatch)])
            {
                // get match data
                [currentView performSelectorOnMainThread:@selector(getMatch) withObject:nil waitUntilDone:YES];
            }
        }
        else if([currentView respondsToSelector:@selector(updateMatchListData)])
        {
            [currentView performSelectorOnMainThread:@selector(updateMatchListData) withObject:nil waitUntilDone:YES];
        }

        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	}
    // match successful notification
	else if(alertType == 2)
	{
        [self.prefs setInteger:1 forKey:@"matchSuccessfulAlert"];
        [self.prefs synchronize];

        if([currentView respondsToSelector:@selector(updateMatchListData)])
        {
            [currentView performSelectorOnMainThread:@selector(updateMatchListData) withObject:nil waitUntilDone:YES];
        }

        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	}
    // new message notification
	else if(alertType == 3)
	{
        int newMessageAlert = [self.prefs integerForKey:@"newMessageAlert"];
        [self.prefs setInteger:newMessageAlert + 1 forKey:@"newMessageAlert"];
        [self.prefs synchronize];

		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:threadContext];
		[request setEntity:entity];
        
		NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo = %d", [matchNo intValue]]];
		[request setPredicate:predicate];
		
		NSError *error = nil;
		NSArray *fetchedObjects = [threadContext executeFetchRequest:request error:&error];
        
		if([fetchedObjects count] > 0)
		{            
            // get new message count
            if([operationQueue operationCount] > 1)
            {
                [operationQueue cancelAllOperations];
            }
            CountNewMessageOperation *countNewMessageOperation = [[CountNewMessageOperation alloc] initWithMatchNo:matchNo];
            [countNewMessageOperation setThreadPriority:0.1];
            [operationQueue addOperation:countNewMessageOperation];
            [countNewMessageOperation release];
		}
		[request release];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldGetNewMessages" object:nil];

		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	}
    // disconnect and delete notifications
	else if(alertType == 4)
	{
        // pop to match list
        [self performSelectorOnMainThread:@selector(popToMatchList) withObject:nil waitUntilDone:YES];

		if([currentView respondsToSelector:@selector(updateMatchListData)])
		{
            [currentView performSelectorOnMainThread:@selector(updateMatchListData) withObject:nil waitUntilDone:YES];
		}
	}
    // new missions notification
    else if(alertType == 5)
    {
        [self.prefs setInteger:1 forKey:@"newMissionAlert"];
        [self.prefs synchronize];

        // if app is active, update mission button on chat view
        if(state == UIApplicationStateActive)
        {
            if(currentView && [currentView respondsToSelector:@selector(setMissionsButton)])
            {
                [currentView performSelectorOnMainThread:@selector(setMissionsButton) withObject:nil waitUntilDone:YES];
            }
        }
        // if app is launched from apn, go to missions view
        else
        {
            // fetch current match
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:threadContext];
            [request setEntity:entity];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = 'Y'"];
            [request setPredicate:predicate];
            NSError *error = nil;
            NSArray *fetchedObjects = [threadContext executeFetchRequest:request error:&error];
            [request release];
            
            if([fetchedObjects count] == 1)
            {                
                // fetch match data
                MatchData *matchData = [fetchedObjects objectAtIndex:0];
                
                NSMutableArray *navStack = [[NSMutableArray alloc] init];
                
                // add main view to nav stack
                UIViewController *mainView = [[self.mainNavController viewControllers] objectAtIndex:0];
                [navStack addObject:mainView];
                
                // add matchlist to nav stack
                [navStack addObject:self.matchlistController];
                
                // add chat view to nav stack
                NewChatViewController *newChatViewController = [[NewChatViewController alloc] initWithNibName:@"NewChatViewController" bundle:nil];
                [newChatViewController setMatchNo:[[matchData valueForKey:@"matchNo"] intValue]];
                [newChatViewController setMatchData:matchData];
                [navStack addObject:newChatViewController];
                [newChatViewController release];

                // add missions to nav stack
                MissionViewControllerOld *missionControllerOld = [[MissionViewControllerOld alloc] initWithNibName:@"MissionViewControllerOld" bundle:nil];
                [missionControllerOld setMatchNo:[[matchData valueForKey:@"matchNo"] intValue]];
                [missionControllerOld setViewTitle:[matchData valueForKey:@"firstName"]];
                [missionControllerOld setDelegate:[navStack objectAtIndex:2]];
                [navStack addObject:missionControllerOld];
                [missionControllerOld release];
                
                CATransition *modalAnimation = [CATransition animation];
                [modalAnimation setDuration:0.6];
                [modalAnimation setType:kCATransitionMoveIn];
                [modalAnimation setSubtype:kCATransitionFromTop];
                [modalAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
                [modalAnimation setDelegate:self];
                [self.mainNavController.view.layer addAnimation:modalAnimation forKey:nil];
                
                // set view controllers
                [self performSelectorOnMainThread:@selector(setNavStack:) withObject:navStack waitUntilDone:YES];
                [navStack release];
                
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            }
        }
    }
}

#pragma mark - UI methods
- (void)loadMainView
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

	// if member number is registered go to match list
	if([self.prefs integerForKey:@"memberNo"] != 0)
	{
        [self showMatchList:NO];
	}

	[UIView beginAnimations:@"loadMainView" context:nil];
	[UIView setAnimationDuration:1.0];
	[self.mainNavController.view setAlpha:1.0];
	[UIView commitAnimations];
}

- (void)showLoading
{
    if(loading == NO)
    {
        loading = YES;
        [loadingView setFrame:self.window.bounds];
        [self.window addSubview:loadingView];
        [loadingView setAlpha:0];
        [UIView beginAnimations:@"showLoading" context:nil];
        [UIView setAnimationDuration:0.5];
        [loadingView setAlpha:1.0];
        [UIView commitAnimations];
    }
}

- (void)hideLoading
{
    if(loading == YES)
    {
        loading = NO;
        [UIView beginAnimations:@"hideLoading" context:nil];
        [UIView setAnimationDuration:0.5];
        [loadingView setAlpha:0];
        [UIView commitAnimations];
        [loadingView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5];
    }
}

- (void)showMatchList:(bool)animated
{
    //self.tabBarController = [[[UITabBarController alloc] init] autorelease];
    //[self.tabBarController setViewControllers:[NSArray arrayWithObjects:self.matchlistController, nil] animated:NO];

    id currentView = [self.mainNavController topViewController];
    if(![currentView respondsToSelector:@selector(getMatch)])
    {
        [self.mainNavController setNavigationBarHidden:NO];
        [self.mainNavController pushViewController:self.matchlistController animated:animated];
        //[self.mainNavController pushViewController:self.tabBarController animated:animated];
    }
}

- (void)showEndMatchAlert
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
    [request setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = 'Y' AND expireDate = %@", [UtilityClasses currentUTCDate]];
    [request setPredicate:predicate];
    
    [request setIncludesPropertyValues:NO];
    
    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    [request release];

    if(count != 0 && [self.prefs boolForKey:@"confirmedEndWarning"] == NO)
    {
        [matchEndAlertPrompt.layer setMasksToBounds:YES];
        [matchEndAlertPrompt.layer setCornerRadius:8.0];
        
        [matchEndConfirmButton.layer setMasksToBounds:YES];
        [matchEndConfirmButton.layer setCornerRadius:5.0];
        [matchEndConfirmButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
        [matchEndConfirmButton.layer setBorderWidth: 1.0];
        [matchEndConfirmButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
        [matchEndConfirmButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
        
        [matchEndAlertView setFrame:self.window.bounds];
        [self.window addSubview:matchEndAlertView];
        [matchEndAlertView setAlpha:0];
        [UIView beginAnimations:@"showMatchAlert" context:nil];
        [UIView setAnimationDuration:1.0];
        [matchEndAlertView setAlpha:1.0];
        [UIView commitAnimations];
    }
}

- (void)displayAlert:(NSDictionary*)content
{
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:[content valueForKey:@"title"] 
						  message:[content valueForKey:@"message"]
						  delegate:self
						  cancelButtonTitle:nil
						  otherButtonTitles:@"OK", nil];

	[alert show];
	[alert release];
}

- (void)displayFatalAlert:(NSDictionary*)content
{
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:[content valueForKey:@"title"] 
						  message:[content valueForKey:@"message"]
						  delegate:self
						  cancelButtonTitle:nil
						  otherButtonTitles:@"OK", nil];
    [alert setTag:500];
	[alert show];
	[alert release];
}

- (void)displayNetworkAlert
{
    [self.overlayWindow showOverlay];
}

- (void)hideNetworkAlert
{
    [self.overlayWindow hideOverlay];
}

- (IBAction)hideEndMatchAlert
{
    [self.prefs setBool:YES forKey:@"confirmedEndWarning"];
    [self.prefs synchronize];
    [UIView beginAnimations:@"hideMatchAlert" context:nil];
	[UIView setAnimationDuration:0.5];
	[matchEndAlertView setAlpha:0];
    [UIView commitAnimations];
    [matchEndAlertView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5];
}

#pragma mark - reachability
- (void)startReachability
{
    internetReach = [[Reachability reachabilityForInternetConnection] retain];
    [internetReach startNotifier];
    
    [self performSelector:@selector(updateInterfaceWithReachability:) withObject:internetReach];
    
    wifiReach = [[Reachability reachabilityForLocalWiFi] retain];
    [wifiReach startNotifier];
    [self performSelector:@selector(updateInterfaceWithReachability:) withObject:wifiReach];

    hostReach = [[Reachability reachabilityWithHostName:apihost] retain];
    [hostReach startNotifier];
    [self performSelector:@selector(updateInterfaceWithReachability:) withObject:hostReach];
}

- (void)stopReachability
{
    [internetReach stopNotifier];
    [wifiReach stopNotifier];
    [hostReach stopNotifier];
}

- (void)reachabilityChanged:(NSNotification* )note
{
	Reachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);

    [self performSelector:@selector(updateInterfaceWithReachability:) withObject:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability*)curReach
{
    NetworkStatus netStatus = [curReach currentReachabilityStatus];

    if(curReach == internetReach)
    {
        if(netStatus == NotReachable)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cancelAllAsyncOperations" object:nil];
            self.networkStatus = [NSNumber numberWithBool:NO];
            [self performSelectorInBackground:@selector(displayNetworkAlert) withObject:nil];
        }
        else
        {
            self.networkStatus = [NSNumber numberWithBool:YES];
            [self performSelectorInBackground:@selector(hideNetworkAlert) withObject:nil];
        }
    }
    else if(curReach == wifiReach)
    {
        #if TARGET_IPHONE_SIMULATOR
        self.wifiStatus = [NSNumber numberWithBool:YES];
        #else
        if(netStatus == NotReachable || [UtilityClasses getWiFiIPAddress] == nil)
        {
            self.wifiStatus = [NSNumber numberWithBool:NO];
        }
        else
        {
            self.wifiStatus = [NSNumber numberWithBool:YES];
        }
        #endif
    }
    else if(curReach == hostReach)
    {
        if(netStatus == NotReachable)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cancelAllAsyncOperations" object:nil];
            self.hostStatus = [NSNumber numberWithBool:NO];
        }
        else
        {
            self.hostStatus = [NSNumber numberWithBool:YES];
        }
    }
}

#pragma mark - Facebook
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI withPermissions:(NSArray*)permissions
{
    return [FBSession openActiveSessionWithPermissions:permissions
                                          allowLoginUI:allowLoginUI
                                     completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                         [self sessionStateChanged:session state:state error:error];
                                     }];
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    switch (state)
    {
        case FBSessionStateOpen:
        {
            if (!error)
            {
                // We have a valid session
            }
            break;
        }
        case FBSessionStateClosed:
        {
            break;
        }
        case FBSessionStateClosedLoginFailed:
        {
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        }
        default:
        {
            break;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YPSessionStateChangedNotification
                                                        object:session];
    
    if (error)
    {
        UIAlertView *alertView = [[[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] autorelease];
        [alertView show];
    }
}

#pragma mark - networking
- (void)didStartNetworking
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
        return;
    }

	networkingCount += 1;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)didStopNetworking
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
        return;
    }

	networkingCount -= 1;
	if(networkingCount <= 0)
	{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        networkingCount = 0;
	}
}

#pragma mark - core data helpers
- (NSManagedObjectContext*)mainMOC
{
    if([NSThread isMainThread] == NO)
    {
        [NSException raise:NSObjectNotAvailableException format:@"Main MOC should not be accessed from background thread"];
        abort();
    }

    return self.managedObjectContext;
}

- (void)saveContext:(NSManagedObjectContext*)context
{
    if(suspendCoreData == YES)
    {
        return;
    }

    NSError *error = nil;
    if (context != nil && [[self.persistentStoreCoordinator persistentStores] count] != 0)
    {
        [context lock];
        if ([context hasChanges] && ![context save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
            abort();
        }
        [context unlock];
    }
}

- (void)clearCoreData
{
    suspendCoreData = YES;

    NSError *error = nil;

    //to drop pending changes
    [self.managedObjectContext lock];
    [self.persistentStoreCoordinator lock];
    [self.managedObjectContext reset];

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"YongoPal.sqlite"];    
    NSPersistentStore *persistentStore = [self.persistentStoreCoordinator persistentStoreForURL:storeURL];
    
    if([self.persistentStoreCoordinator removePersistentStore:persistentStore error:&error])
    {
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"YongoPal.sqlite"];
        [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];

        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSMigratePersistentStoresAutomaticallyOption, nil];
        
        NSError *error = nil;

        if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
        {
            if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
            abort();
        }
    }
    [self.persistentStoreCoordinator unlock];
    [self.managedObjectContext unlock];
    
    suspendCoreData = NO;
}

- (void)updateMigrationProgress
{
    int percent = migrationProgress * 100;
    
    [self.migrationProgressView setProgress:migrationProgress];
    
    if(percent != 0)
    {
        [self.migrationSpinner stopAnimating];
        [self.migrationProgressLabel setHidden:NO];
        [self.migrationProgressLabel setText:[NSString stringWithFormat:@"%d%%", percent]];
    }
    else
    {
        [self.migrationSpinner startAnimating];
        [self.migrationProgressLabel setHidden:YES];
    }
}

- (BOOL)progressivelyMigrateURL:(NSURL*)sourceStoreURL ofType:(NSString*)type toModel:(NSManagedObjectModel*)finalModel
{
    NSError *error = nil;
    
    // if store dosen't exist skip migration
    NSString *documentDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    if(![NSBundle pathForResource:@"YongoPal" ofType:@"sqlite" inDirectory:documentDir])
    {
        migrationProgress = 1.0;
        [self performSelectorOnMainThread:@selector(updateMigrationProgress) withObject:nil waitUntilDone:YES];
        
        // remove migration view
        [self.migrationView performSelectorOnMainThread:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
        [self.migrationView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
        
        self.migrationView = nil;
        self.migrationProgressLabel = nil;
        self.migrationProgressView = nil;
        self.migrationSpinner = nil;

        return YES;
    }

    //START:progressivelyMigrateURLHappyCheck
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type URL:sourceStoreURL error:&error];

    if (!sourceMetadata)
    {
        return NO;
    }

    if ([finalModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata])
    {
        migrationProgress = 1.0;
        [self performSelectorOnMainThread:@selector(updateMigrationProgress) withObject:nil waitUntilDone:YES];

        // remove migration view
        [self.migrationView performSelectorOnMainThread:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
        [self.migrationView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];

        self.migrationView = nil;
        self.migrationProgressLabel = nil;
        self.migrationProgressView = nil;
        self.migrationSpinner = nil;
        
        error = nil;
        return YES;
    }
    else
    {
        migrationProgress = 0.0;
        [self.migrationView performSelectorOnMainThread:@selector(setHidden:) withObject:NO waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(updateMigrationProgress) withObject:nil waitUntilDone:YES];        
    }
    //END:progressivelyMigrateURLHappyCheck
    
    //START:progressivelyMigrateURLFindModels
    //Find the source model
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:sourceMetadata];
    if(sourceModel == nil)
    {
        NSLog(@"%@", [NSString stringWithFormat:@"Failed to find source model\n%@", [sourceMetadata description]]);
        return NO;
    }
    
    //Find all of the mom and momd files in the Resources directory
    NSMutableArray *modelPaths = [NSMutableArray array];
    NSArray *momdArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd" inDirectory:nil];
    for (NSString *momdPath in momdArray)
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        NSString *resourceSubpath = [momdPath lastPathComponent];
        NSArray *array = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom" inDirectory:resourceSubpath];
        [modelPaths addObjectsFromArray:array];
        [pool drain];
    }
    
    NSArray* otherModels = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom" inDirectory:nil];
    [modelPaths addObjectsFromArray:otherModels];
    
    if (!modelPaths || ![modelPaths count])
    {
        //Throw an error if there are no models
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"No models found in bundle" forKey:NSLocalizedDescriptionKey];
        
        //Populate the error
        error = [NSError errorWithDomain:@"com.yongopal.coredata" code:500 userInfo:dict];
        if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
        {
            NSLog(@"error: %@", error);
        }
        return NO;
    }
    //END:progressivelyMigrateURLFindModels
    
    //See if we can find a matching destination model
    //START:progressivelyMigrateURLFindMap
    NSMappingModel *mappingModel = nil;
    NSManagedObjectModel *targetModel = nil;
    NSString *modelPath = nil;
    
    for(modelPath in modelPaths)
    {
        targetModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
        mappingModel = [NSMappingModel mappingModelFromBundles:nil forSourceModel:sourceModel destinationModel:targetModel];
        
        //If we found a mapping model then proceed
        if(mappingModel)
        {
            break;
        }
        else
        {
            //Release the target model and keep looking
            [targetModel release];
            targetModel = nil;
        }
    }
    
    //We have tested every model, if nil here we failed
    if (!mappingModel)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"No mapping models found in bundle" forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:@"com.yongopal.coredata" code:500 userInfo:dict];
        if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
        {
            NSLog(@"error: %@", error);
        }
        return NO;
    }
    //END:progressivelyMigrateURLFindMap
    
    //We have a mapping model and a destination model.  Time to migrate
    //START:progressivelyMigrateURLMigrate
    NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:targetModel];

    // reg KVO for migration progress
    [manager addObserver:self forKeyPath:@"migrationProgress" options:NSKeyValueObservingOptionNew context:NULL];
    
    NSString *modelName = [[modelPath lastPathComponent] stringByDeletingPathExtension];
    NSString *storeExtension = [[sourceStoreURL path] pathExtension];
    NSString *storePath = [[sourceStoreURL path] stringByDeletingPathExtension];
    
    //Build a path to write the new store
    storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath, modelName, storeExtension];
    NSURL *destinationStoreURL = [NSURL fileURLWithPath:storePath];
    
    if (![manager migrateStoreFromURL:sourceStoreURL type:type options:nil withMappingModel:mappingModel toDestinationURL:destinationStoreURL destinationType:type destinationOptions:nil error:&error])
    {
        if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
        {
            NSLog(@"error: %@", error);
        }
        [targetModel release];
        [manager removeObserver:self forKeyPath:@"migrationProgress"];
        [manager release];
        return NO;
    }
    [targetModel release];
    [manager removeObserver:self forKeyPath:@"migrationProgress"];
    [manager release];
    //END:progressivelyMigrateURLMigrate
    
    //Migration was successful, move the files around to preserve the source
    //START:progressivelyMigrateURLMoveAndRecurse
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    guid = [guid stringByAppendingPathExtension:modelName];
    guid = [guid stringByAppendingPathExtension:storeExtension];
    NSString *appSupportPath = [storePath stringByDeletingLastPathComponent];
    NSString *backupPath = [appSupportPath stringByAppendingPathComponent:guid];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager moveItemAtPath:[sourceStoreURL path] toPath:backupPath error:&error])
    {
        if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
        {
            NSLog(@"error: %@", error);
        }
        //Failed to copy the file
        return NO;
    }
    
    //Move the destination to the source path
    if (![fileManager moveItemAtPath:storePath toPath:[sourceStoreURL path] error:&error])
    {
        if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
        {
            NSLog(@"error: %@", error);
        }
        //Try to back out the source move first, no point in checking it for errors
        [fileManager moveItemAtPath:backupPath toPath:[sourceStoreURL path] error:nil];
        return NO;
    }

    //We may not be at the "current" model yet, so recurse
    return [self progressivelyMigrateURL:sourceStoreURL ofType:type toModel:finalModel];
    //END:progressivelyMigrateURLMoveAndRecurse
}

#pragma mark - APIRequest delegate
- (void)didReceiveJson:(NSDictionary*)jsonObject andHeaders:(NSDictionary*)headers
{
    NSString *request = [jsonObject valueForKey:@"request"];
    NSString *task = [jsonObject valueForKey:@"task"];
    NSDictionary *resultData = [jsonObject valueForKey:@"result"];

    // file upload succeeded
    if([request isEqualToString:@"member"] && [task isEqualToString:@"uploadPhoto"])
    {
        if([[resultData valueForKey:@"affectedRows"] intValue] == 1)
        {
            [self.prefs setValue:@"Y" forKey:@"uploadSuccessful"];
            [self.prefs synchronize];
        }
        else
        {
            [self.prefs setValue:@"N" forKey:@"uploadSuccessful"];
            [self.prefs synchronize];
        }
    }
}

#pragma mark - alertView delegate
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(actionSheet.tag == 500)
    {
        exit(0);
    }
}

#pragma mark - Core Data stack
/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if(__managedObjectContext == nil)
    {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil)
        {
            __managedObjectContext = [[NSManagedObjectContext alloc] init];
            [__managedObjectContext setPersistentStoreCoordinator:coordinator];
            [__managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        }
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"YongoPal" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"YongoPal.sqlite"];

	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSMigratePersistentStoresAutomaticallyOption, nil];

    NSError *error = nil;

    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        if([[self.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }

        // reset core data if something goes wrong
        NSFileManager *localFileManager = [[NSFileManager alloc] init];
        [localFileManager removeItemAtURL:storeURL error:NULL];
        [localFileManager release];

        abort();
    }

    return __persistentStoreCoordinator;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqual:@"migrationProgress"])
    {
        migrationProgress = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        [self performSelectorOnMainThread:@selector(updateMigrationProgress) withObject:nil waitUntilDone:YES];
    }
}

@end