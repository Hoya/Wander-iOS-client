//
//  YongoPalAppDelegate.h
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

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Reachability.h"
#import "APIRequest.h"
#import "ThreadMOC.h"
#import "OpenUDID.h"

// Localytics
#import "LocalyticsSession.h"

// Crittercism
#import "Crittercism.h"

// FB
#import "Facebook.h"

// Categories
#import "UINavigationController+Autorotation.h"
#import "UINavigationBar+CustomBackground.h"
#import "UINavigationItem+CustomTitle.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Alpha.h"
#import "UIImage+URL.h"
#import "NSString+Base64.h"
#import "NSString+Urlencode.h"
#import "CLLocationManager+SimulatorHack.h"

// custom subclasses
#import "CUIButton.h"
#import "StatusBarOverlayWindow.h"

#define yongoApiKey @""
#define twitterKey @""
#define twitterSecret @""
#define foursquareKey @""
#define foursquareSecret @""
#define foursquareRedirect @"http://"
#define bitlyKey @""
#define googleTranslateKey @""

#if DEBUG
#define apihost @""
#define development @""
#define localyticsApiKey @""
#define critterAppId @""
#define critterKey @""
#define critterSecret @""
#define fbAppId @""
/*
#define apihost @""
#define development @""
#define localyticsApiKey @""
#define critterAppId @""
#define critterKey @""
#define critterSecret @""
#define fbAppId @""
 */
#endif

#if DEBUGBETA
#define apihost @""
#define development @""
#define localyticsApiKey @""
#define critterAppId @""
#define critterKey @""
#define critterSecret @""
#define fbAppId @""
#endif

#if BETA
#define apihost @""
#define development @""
#define localyticsApiKey @""
#define critterAppId @""
#define critterKey @""
#define critterSecret @""
#define fbAppId @""
#endif

#if DEBUGRELEASE
#define apihost @""
#define development @""
#define localyticsApiKey @""
#define critterAppId @""
#define critterKey @""
#define critterSecret @""
#define fbAppId @""
#endif

#if RELEASE
#define apihost @""
#define development @""
#define localyticsApiKey @""
#define critterAppId @""
#define critterKey @""
#define critterSecret @""
#define fbAppId @""
#endif

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define DEGREES_TO_RADIANS(x) (M_PI * x / 180.0)
//void uncaughtExceptionHandler(NSException *exception);

extern NSString *const YPSessionStateChangedNotification;

@class MatchListViewController;
@class MainViewController;
@class APIRequest;
@interface YongoPalAppDelegate : NSObject
<
	UIApplicationDelegate,
	UIAlertViewDelegate,
    APIRequestDelegate
>
{
    APIRequest *apiRequest;
    NSUserDefaults *prefs;
    NSString *apiHost;
    NSString *productionStage;
    NSOperationQueue *operationQueue;
    NSOperationQueue *launchAppQueue;
    UIBackgroundTaskIdentifier bgTask;
    NSMutableArray *announcements;

    // UI objects
	UIWindow *window;
    UITabBarController *tabBarController;
	UIView *loadingView;
    UIView *matchEndAlertView;
    UIView *matchEndAlertPrompt;
    CUIButton *matchEndConfirmButton;
    UIView *migrationView;
    UILabel *migrationProgressLabel;
    UIProgressView *migrationProgressView;
    UIActivityIndicatorView *migrationSpinner;
    StatusBarOverlayWindow *overlayWindow;

    // FB objects
	NSMutableArray *defaultPermissions;
    
    // Reachability
    Reachability *internetReach;
    Reachability *wifiReach;
    Reachability *hostReach;
    NSNumber *networkStatus;
    NSNumber *wifiStatus;
    NSNumber *hostStatus;

    // ids
    id currentReach;
    
    // primitive variables
	int networkingCount;
    bool shouldUpdateMatchList;
    bool loading;
    float migrationProgress;
    bool suspendCoreData;
}

@property (nonatomic, retain) APIRequest *apiRequest;
@property (nonatomic, retain) NSUserDefaults *prefs;
@property (nonatomic, retain) NSString *apiHost;
@property (nonatomic, retain) NSString *productionStage;
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, retain) NSMutableArray *announcements;

/* UI objects */
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) UINavigationController *mainNavController;
@property (nonatomic, retain) MainViewController *mainViewController;
@property (nonatomic, retain) MatchListViewController *matchlistController;
@property (nonatomic, retain) IBOutlet UIView *loadingView;
@property (nonatomic, retain) IBOutlet UIView *matchEndAlertView;
@property (nonatomic, retain) IBOutlet UIView *matchEndAlertPrompt;
@property (nonatomic, retain) IBOutlet CUIButton *matchEndConfirmButton;
@property (nonatomic, retain) IBOutlet UIView *migrationView;
@property (nonatomic, retain) IBOutlet UILabel *migrationProgressLabel;
@property (nonatomic, retain) IBOutlet UIProgressView *migrationProgressView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *migrationSpinner;
@property (nonatomic, retain) StatusBarOverlayWindow *overlayWindow;

/* FB objects */
@property (nonatomic, retain) NSMutableArray *defaultPermissions;

/* reachability */
@property (nonatomic, retain) NSNumber *networkStatus;
@property (nonatomic, retain) NSNumber *wifiStatus;
@property (nonatomic, retain) NSNumber *hostStatus;

/* primitive variables */
@property (nonatomic, readwrite) bool shouldUpdateMatchList;
@property (nonatomic, readwrite) int networkingCount;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (YongoPalAppDelegate *)sharedAppDelegate;

// application
- (void)launchAppWithOptions:(NSDictionary *)launchOptions;
- (void)setApplicationBadgeNumber:(NSNumber*)badge;
- (void)updateViews;
- (void)resetAllData;
- (void)clearUserPrefs;
- (void)deleteAllImageFiles;
- (NSURL *)applicationDocumentsDirectory;
- (void)updateTimezoneData;
- (void)updateAnnouncements;

// Wander API helpers
- (void)updateMemberLocation;
- (void)confirmCrossPost:(NSDictionary*)userData;
- (void)resumeProfileImageUpload;
- (void)resumeCrosspostLogSync;
- (void)updateMemberLocale;

// navigation
- (void)popToMatchList;
- (void)setNavStack:(NSArray*)navStack;

// apn helpers
- (void)registerDevice;
- (void)unregisterDevice;
- (void)confirmPushNotifications:(NSData *)devToken;
- (bool)pushStatus;
- (void)launchNotification:(NSDictionary *)userInfo;

// UI methods
- (void)loadMainView;
- (void)showLoading;
- (void)hideLoading;
- (void)showMatchList:(bool)animated;
- (void)showEndMatchAlert;
- (void)displayAlert:(NSDictionary*)content;
- (void)displayFatalAlert:(NSDictionary*)content;
- (void)displayNetworkAlert;
- (void)hideNetworkAlert;
- (IBAction)hideEndMatchAlert;

// reachability
- (void)startReachability;
- (void)stopReachability;
- (void)reachabilityChanged:(NSNotification* )note;
- (void)updateInterfaceWithReachability:(Reachability*)curReach;

// facebook
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error;
- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI withPermissions:(NSArray*)permissions;

// networking
- (void)didStartNetworking;
- (void)didStopNetworking;

// Core Data Helpers
- (NSManagedObjectContext*)mainMOC;
- (void)saveContext:(NSManagedObjectContext*)context;
- (void)clearCoreData;
- (void)updateMigrationProgress;
- (BOOL)progressivelyMigrateURL:(NSURL*)sourceStoreURL ofType:(NSString*)type toModel:(NSManagedObjectModel*)finalModel;

@end