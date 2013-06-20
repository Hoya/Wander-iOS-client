//
//  MatchListViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 4/11/11.
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

#import "MatchListViewController.h"

#import "FeedbackViewController.h"
#import "ProfileViewController.h"
#import "MatchIntroViewController.h"
#import "QuickMatchViewController.h"
#import "WebViewController.h"

#import "AddMatchOperation.h"
#import "UpdateMatchListOperation.h"
#import "CountNewMessageOperation.h"
#import "CancelQuickMatchOperation.h"

#import "UtilityClasses.h"
#import "MatchData.h"
#import "Announcements.h"

#import "CUIButton.h"

@implementation MatchListViewController
@synthesize apiRequest;
@synthesize resultsController;
@synthesize _tableView;
@synthesize getMatchView;
@synthesize completeProfileView;
@synthesize noResponseView;
@synthesize noResponseBubble;
@synthesize unlockPromptView;
@synthesize unlockPromptBubble;
@synthesize unlockPromptLabel;
@synthesize extraGuideAlertView;
@synthesize extraGuideAlertBubble;
@synthesize modalView;
@synthesize leaveAlert;
@synthesize leaveAlertMessage;
@synthesize confirmLeave;
@synthesize cancelLeave;
@synthesize stopQuickMatchView;
@synthesize stopQuickMatchDialog;
@synthesize confirmStopButton;
@synthesize cancelStopButton;
@synthesize deleteMatchView;
@synthesize deleteMatchDialog;
@synthesize cancelDeleteButton;
@synthesize confirmDeleteButton;
@synthesize modalView2;
@synthesize dumpedAlert;
@synthesize dumpedAlertMessage;
@synthesize confirmDumped;
@synthesize searchIndicator;
@synthesize isFirstRun;
@synthesize shouldReloadTableData;
@synthesize selectedCell;
@synthesize timer;

#define MAX_CACHED_IMAGES 30

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        self.apiRequest = [[[APIRequest alloc] init] autorelease];
        [self.apiRequest setDelegate:self];
        
        // update match list operation
        updateMatchesOperationQueue = [[NSOperationQueue alloc] init];
        [updateMatchesOperationQueue setMaxConcurrentOperationCount:1];
        
        updateMessagesOperationQueue = [[NSOperationQueue alloc] init];
        [updateMessagesOperationQueue setMaxConcurrentOperationCount:1];
        
        requestOperationQueue = [[NSOperationQueue alloc] init];
        [requestOperationQueue setMaxConcurrentOperationCount:1];
        
        // set operation stuff
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:4];
        
        // start photo cache
        photoCache = [[NSMutableDictionary alloc] init];
        
        loadingCells = [[NSMutableArray alloc] init];

        // register notifications
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(clearInvalidMatches) name:@"shouldClearInvalidMatches" object:nil];
        [dnc addObserver:self selector:@selector(downloadThumbnail:) name:@"downloadThumbnail" object:nil];
        [dnc addObserver:self selector:@selector(shouldShowDumpedAlert:) name:@"showDumpedAlert" object:nil];
        [dnc addObserver:self selector:@selector(shouldShowSearchIndicator:) name:@"showSearchIndicator" object:nil];
        [dnc addObserver:self selector:@selector(shouldHideSearchIndicator:) name:@"hideSearchIndicator" object:nil];
        [dnc addObserver:self selector:@selector(updateMatchListData) name:@"shouldUpdateMatchList" object:nil];
        [dnc addObserver:self selector:@selector(setProfileThumbnail) name:@"profileImageDownloaded" object:nil];
        [dnc addObserver:self selector:@selector(showAnnouncementAlert) name:@"receivedAnnouncement" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.getMatchView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.modalView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.leaveAlert];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.modalView2];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.dumpedAlert];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.stopQuickMatchView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.stopQuickMatchDialog];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.deleteMatchView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.deleteMatchDialog];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.noResponseView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.unlockPromptView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.extraGuideAlertView];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.timer invalidate];
    self.timer = nil;

    [apiRequest release];
    [updateMatchesOperationQueue cancelAllOperations];
    [updateMatchesOperationQueue release];
    [updateMessagesOperationQueue cancelAllOperations];
    [updateMessagesOperationQueue release];
    [requestOperationQueue cancelAllOperations];
    [requestOperationQueue release];
    [operationQueue cancelAllOperations];
    [operationQueue release];

	[_tableView release];
	[getMatchView release];
	[completeProfileView release];
    [noResponseView release];
    [noResponseBubble release];
    [unlockPromptView release];
    [unlockPromptBubble release];
    [unlockPromptLabel release];
    [extraGuideAlertView release];
    [extraGuideAlertBubble release];
    [resultsController setDelegate:nil];
	[resultsController release];
    [photoCache release];
    [loadingCells release];
	
	[modalView release];
	[leaveAlert release];
	[leaveAlertMessage release];
	[confirmLeave release];
	[cancelLeave release];
    
    [stopQuickMatchView release];
    [stopQuickMatchDialog release];
    [confirmStopButton release];
    [cancelStopButton release];
    
    [deleteMatchView release];
    [deleteMatchDialog release];
    [cancelDeleteButton release];
    [confirmDeleteButton release];
	
	[modalView2 release];
	[dumpedAlert release];
	[dumpedAlertMessage release];
	[confirmDumped release];
	
	[searchIndicator release];

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
    
    // set timer for table view so that the local time for guides properly update
    if(self.timer == nil)
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self._tableView selector:@selector(reloadData) userInfo:nil repeats:YES];
    }

    [appDelegate.mainNavController setNavigationBarHidden:NO];

    /*
    UITabBarItem *guideTab = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemContacts tag:0];
    [self setTabBarItem:guideTab];
    [guideTab release];
    [self.tabBarItem setTitle:@"Local Guide"];
    [self.tabBarController.navigationItem setCustomTitle:NSLocalizedString(@"matchListTitle", nil)];
     */
    
    [self.navigationItem setCustomTitle:NSLocalizedString(@"matchListTitle", nil)];
    
    // set the user thumbnail for settings button
	[self setProfileThumbnail];

    // Do any additional setup after loading the view from its nib.
	NSFetchRequest *matchListRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:appDelegate.mainMOC];
    [matchListRequest setEntity:entity];
    [matchListRequest setReturnsObjectsAsFaults:YES];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status != 'X' and status != 'D'"];
	[matchListRequest setPredicate:predicate];

	NSSortDescriptor *sortDescripter = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSSortDescriptor *sortDescripter2 = [[NSSortDescriptor alloc] initWithKey:@"activeDate" ascending:NO];
    NSSortDescriptor *sortDescripter3 = [[NSSortDescriptor alloc] initWithKey:@"matchNo" ascending:NO];
	NSArray *sortDescripters = [[NSArray alloc] initWithObjects:sortDescripter, sortDescripter2, sortDescripter3, nil];
	[matchListRequest setSortDescriptors:sortDescripters];
	[sortDescripters release];
	[sortDescripter release];
    [sortDescripter2 release];
    [sortDescripter3 release];

	NSFetchedResultsController *fetchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:matchListRequest 
															managedObjectContext:appDelegate.mainMOC
															sectionNameKeyPath:@"order"
															cacheName:@"matchList.cache"];
    [fetchResultsController setDelegate:self];
	[matchListRequest release];

	NSError *error;
	BOOL success = [fetchResultsController performFetch:&error];
	if(!success)
	{
		NSLog(@"setProgramList error: %@", error);
	}
    
    self.resultsController = fetchResultsController;
    [fetchResultsController release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // resize navigation bar and table view
	CGRect navBarFrame = [[appDelegate.mainNavController navigationBar] frame];
	CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, navBarFrame.size.height);
    [[appDelegate.mainNavController navigationBar] resizeBGLayer:newFrame];
    [[appDelegate.mainNavController navigationBar] removeCaptions];

    // hide search indicator
    [self hideSearchIndicator];

    // update match list if needed
	if([appDelegate.networkStatus boolValue] == YES)
	{
        if([[appDelegate.prefs valueForKey:@"active"] isEqualToString:@"Y"] && isFirstRun != YES)
        {
            // update match list
            [self updateMatchListData];
        }
        [self updateNewMessageAlerts];
    }
	
	isLoadingChat = NO;
	isUpdatingMatches = NO;
    
    if([[appDelegate.prefs valueForKey:@"active"] isEqualToString:@"N"])
    {
        [self performSelector:@selector(showCompleteProfileView)];
    }
    else
    {
        [completeProfileView removeFromSuperview];
    }
    
    [self updateMatchView];
    
    // check latest match
    [self performSelectorInBackground:@selector(checkLatestMatch) withObject:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	// check if match was dumped
	if([appDelegate.prefs integerForKey:@"wasDumped"] == 1)
	{
		[self showDumpedAlert:[appDelegate.prefs valueForKey:@"wasDumpedBy"]];
	}

    if([appDelegate.prefs boolForKey:@"didRateApp"] != YES)
    {
        NSArray *currentSessions = [self currentSessions:appDelegate.mainMOC];

        NSTimeInterval timeZoneOffset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
        NSTimeInterval gmtTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] - timeZoneOffset;
        NSDate *gmtDate = [NSDate dateWithTimeIntervalSinceReferenceDate:gmtTimeInterval];

        // prompt to rate if session has been active for 3 days
        if([appDelegate.prefs boolForKey:@"didRateApp"] != YES)
        {
            NSMutableArray *allSessions = [[NSMutableArray alloc] initWithArray:currentSessions];
            [allSessions addObjectsFromArray:[self expiredSessions:appDelegate.mainMOC]];

            for(MatchData *session in allSessions)
            {
                NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDateComponents *sessionAgeComponents = [gregorian components:NSDayCalendarUnit fromDate:session.matchDatetime toDate:gmtDate options:0];
                int sessionAge = [sessionAgeComponents day];
                
                NSTimeInterval lastPromptTimeInterval = [appDelegate.prefs floatForKey:@"remindToRateApp"];
                NSDateComponents *reminderComponents = [gregorian components:NSDayCalendarUnit fromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:lastPromptTimeInterval] toDate:gmtDate options:0];
                int daysSinceLastPrompt = [reminderComponents day];
                [gregorian release];
                
                NSSet *chatData = session.chatData;
                
                // get received messages
                NSPredicate *receivedMessagePredicate = [NSPredicate predicateWithFormat:@"sender != %d", [appDelegate.prefs integerForKey:@"memberNo"]];
                NSSet *receivedMessages = [chatData filteredSetUsingPredicate:receivedMessagePredicate];
                
                // get sent messages
                NSPredicate *sentMessagePredicate = [NSPredicate predicateWithFormat:@"sender = %d", [appDelegate.prefs integerForKey:@"memberNo"]];
                NSSet *sentMessages = [chatData filteredSetUsingPredicate:sentMessagePredicate];

                if(daysSinceLastPrompt > 7 && sessionAge > 2)
                {
                    if([sentMessages count] > 3 && [receivedMessages count] > 3)
                    {
                        [self promptRating];
                        break;
                    }
                }
            }
            [allSessions release];
        }
    }
    
    if(shouldReloadTableData == YES)
    {
        shouldReloadTableData = NO;
        [self._tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissUnlockPromptView];
	[super viewWillDisappear:animated];
    isSearching = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.getMatchView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.modalView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.leaveAlert];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.modalView2];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.dumpedAlert];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.stopQuickMatchView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.stopQuickMatchDialog];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.deleteMatchView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.deleteMatchDialog];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.noResponseView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.unlockPromptView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.extraGuideAlertView];

    [self.timer invalidate];
    self.timer = nil;

    [self.resultsController setDelegate:nil];
    self.resultsController = nil;
    self._tableView = nil;
    self.getMatchView = nil;
    self.completeProfileView = nil;
    self.noResponseView = nil;
    self.noResponseBubble = nil;
    self.unlockPromptView = nil;
    self.unlockPromptBubble = nil;
    self.unlockPromptLabel = nil;
    self.extraGuideAlertView = nil;
    self.extraGuideAlertBubble = nil;
    self.modalView = nil;
    self.leaveAlert = nil;
    self.leaveAlertMessage = nil;
    self.confirmLeave = nil;
    self.cancelLeave = nil;
    self.stopQuickMatchView = nil;
    self.stopQuickMatchDialog = nil;
    self.confirmStopButton = nil;
    self.cancelStopButton = nil;
    self.deleteMatchView = nil;
    self.deleteMatchDialog = nil;
    self.cancelDeleteButton = nil;
    self.confirmDeleteButton = nil;
    self.modalView2 = nil;
    self.dumpedAlert = nil;
    self.dumpedAlertMessage = nil;
    self.confirmDumped = nil;
    self.searchIndicator = nil;
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

#pragma mark - main UI methods
- (void)updateMatchView
{
    if([[self.resultsController sections] count] == 0 && isSearching == NO)
    {
        [self.view insertSubview:getMatchView aboveSubview:_tableView];
        [getMatchView setAlpha:0];
        
        [UIView beginAnimations:@"showGetMatchView" context:nil];
        [UIView setAnimationDuration:0.25];
        [getMatchView setAlpha:1];
        [UIView commitAnimations];
    }
    else
    {
        [UIView beginAnimations:@"showGetMatchView" context:nil];
        [UIView setAnimationDuration:0.25];
        [getMatchView setAlpha:0];
        [UIView commitAnimations];
        
        [getMatchView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5];
    }
}

- (void)setProfileThumbnail
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
        return;
    }

	// set top left button image
	NSString *imagesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images"];
	NSString *imagePath = [NSBundle pathForResource:@"profileImageIcon" ofType:@"png" inDirectory:imagesDirectory];
    
	UIImage *settingsImage = nil;
	if([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
	{
		settingsImage = [UIImage imageWithContentsOfFile:imagePath];
	}
	else
	{
		settingsImage = [UIImage imageNamed:@"btn_settings.png"];
	}
    
	CGRect settingsFrame = CGRectMake(0, 0, settingsImage.size.width, settingsImage.size.height);
    
	CUIButton *settingsButton = [[CUIButton alloc] initWithFrame:settingsFrame];
	[settingsButton setBackgroundImage:settingsImage forState:UIControlStateNormal];
	[settingsButton setShowsTouchWhenHighlighted:YES];
	[settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
	[settingsButton.layer setMasksToBounds:YES];
	[settingsButton.layer setCornerRadius:4];
	UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
    [self.navigationItem setLeftBarButtonItem:settingsBarButtonItem];
	[settingsBarButtonItem release];
	[settingsButton release];
}

- (void)showSearchIndicator
{
    [[self.navigationItem rightBarButtonItem] setEnabled:NO];
    
    [searchIndicator setFrame:CGRectMake(0, 0-searchIndicator.frame.size.height, searchIndicator.frame.size.width, searchIndicator.frame.size.height)];
    [searchIndicator setHidden:NO];
    
    [UIView beginAnimations:@"ShowSearchIndicator" context:nil];
    [UIView setAnimationDuration:0.25];
    [searchIndicator setFrame:CGRectMake(0, 0, searchIndicator.frame.size.width, searchIndicator.frame.size.height)];
    [_tableView setFrame:CGRectMake(_tableView.frame.origin.x, 0 + searchIndicator.frame.size.height, _tableView.frame.size.width, _tableView.frame.size.height - searchIndicator.frame.size.height)];
    [UIView commitAnimations];
}

- (void)hideSearchIndicator
{
    [[self.navigationItem rightBarButtonItem] setEnabled:YES];
    
    [UIView beginAnimations:@"hideSearchIndicator" context:nil];
	[UIView setAnimationDuration:0.25];
	[searchIndicator setFrame:CGRectMake(0, 0-searchIndicator.frame.size.height, searchIndicator.frame.size.width, searchIndicator.frame.size.height)];
	[_tableView setFrame:CGRectMake(_tableView.frame.origin.x, 0, _tableView.frame.size.width, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES])];
	[UIView commitAnimations];
    
    isSearching = NO;
}

- (void)showLeaveAlert
{
	[leaveAlert.layer setMasksToBounds:YES];
	[leaveAlert.layer setCornerRadius:8.0];
	
	[confirmLeave.layer setMasksToBounds:YES];
	[confirmLeave.layer setCornerRadius:5.0];
	[confirmLeave.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[confirmLeave.layer setBorderWidth: 1.0];
	[confirmLeave setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[confirmLeave setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
	
	[cancelLeave.layer setMasksToBounds:YES];
	[cancelLeave.layer setCornerRadius:5.0];
	[cancelLeave.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[cancelLeave.layer setBorderWidth: 1.0];
	[cancelLeave setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[cancelLeave setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
	
	[modalView setAlpha:0.0];
	
	[modalView setHidden:NO];
	[leaveAlert setHidden:NO];

    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];

    leaveAlertMessage.text = [leaveAlertMessage.text stringByReplacingOccurrencesOfString:@"{partner}" withString:[matchData valueForKey:@"firstName"]];
    
    [modalView setFrame:self.view.bounds];
	[self.view addSubview:modalView];
	
	[UIView beginAnimations:@"showResultView" context:nil];
	[UIView setAnimationDuration:0.25];
	[modalView setAlpha:1.0];
	[UIView commitAnimations];
}

- (void)hideLeaveAlert
{
	[UIView beginAnimations:@"hideResultView" context:nil];
	[UIView setAnimationDuration:0.25];
	[modalView setAlpha:0.0];
	[UIView commitAnimations];
    
	[modalView performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
	[leaveAlert performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
	[modalView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
}


- (void)showDumpedAlert:(NSString*)firstName
{
    if(firstName != nil)
    {
        [dumpedAlert.layer setMasksToBounds:YES];
        [dumpedAlert.layer setCornerRadius:8.0];
        
        [confirmDumped.layer setMasksToBounds:YES];
        [confirmDumped.layer setCornerRadius:5.0];
        [confirmDumped.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
        [confirmDumped.layer setBorderWidth: 1.0];
        [confirmDumped setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
        [confirmDumped setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
        
        NSString *dumpedMessage = [dumpedAlertMessage text];
        dumpedMessage = [dumpedMessage stringByReplacingOccurrencesOfString:@"{partnerName}" withString:firstName];
        [dumpedAlertMessage setText:dumpedMessage];
        
        [modalView2 setAlpha:0.0];
        
        [modalView2 setHidden:NO];
        [dumpedAlert setHidden:NO];
        [modalView2 setFrame:self.view.bounds];
        [self.view addSubview:modalView2];
        
        [UIView beginAnimations:@"showDumpedView" context:nil];
        [UIView setAnimationDuration:0.25];
        [modalView2 setAlpha:1.0];
        [UIView commitAnimations];
    }
}

- (void)hideDumpedAlert
{
	[UIView beginAnimations:@"hideDumpedView" context:nil];
	[UIView setAnimationDuration:0.25];
	[modalView2 setAlpha:0.0];
	[UIView commitAnimations];
	
	[modalView2 performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
    [dumpedAlert performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
    [modalView2 performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
}

- (void)showGetMatchView
{
    [getMatchView setFrame:self._tableView.bounds];
    [self.view insertSubview:getMatchView aboveSubview:_tableView];
}

- (void)showCompleteProfileView
{
    [completeProfileView setFrame:self._tableView.bounds];
    [self.view insertSubview:completeProfileView aboveSubview:_tableView];
}

- (void)showStopQuickMatchPrompt
{
    [stopQuickMatchDialog.layer setMasksToBounds:YES];
	[stopQuickMatchDialog.layer setCornerRadius:8.0];
	
	[confirmStopButton.layer setMasksToBounds:YES];
	[confirmStopButton.layer setCornerRadius:5.0];
	[confirmStopButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[confirmStopButton.layer setBorderWidth: 1.0];
	[confirmStopButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[confirmStopButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
	
	[cancelStopButton.layer setMasksToBounds:YES];
	[cancelStopButton.layer setCornerRadius:5.0];
	[cancelStopButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[cancelStopButton.layer setBorderWidth: 1.0];
	[cancelStopButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[cancelStopButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
	
	[stopQuickMatchView setAlpha:0.0];
	
	[stopQuickMatchView setHidden:NO];
	[stopQuickMatchDialog setHidden:NO];
    
    [stopQuickMatchView setFrame:self.view.bounds];
	[self.view addSubview:stopQuickMatchView];
	
	[UIView beginAnimations:@"showStopView" context:nil];
	[UIView setAnimationDuration:0.25];
	[stopQuickMatchView setAlpha:1.0];
	[UIView commitAnimations];
}

- (void)hideStopQuickMatchPrompt
{
    [UIView beginAnimations:@"hideStopView" context:nil];
	[UIView setAnimationDuration:0.25];
	[stopQuickMatchView setAlpha:0.0];
	[UIView commitAnimations];
    
	[stopQuickMatchView performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
	[stopQuickMatchDialog performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
	[stopQuickMatchView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
}

- (void)showDeleteMatchPrompt
{
    [deleteMatchDialog.layer setMasksToBounds:YES];
	[deleteMatchDialog.layer setCornerRadius:8.0];
	
	[confirmDeleteButton.layer setMasksToBounds:YES];
	[confirmDeleteButton.layer setCornerRadius:5.0];
	[confirmDeleteButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[confirmDeleteButton.layer setBorderWidth: 1.0];
	[confirmDeleteButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[confirmDeleteButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
	
	[cancelDeleteButton.layer setMasksToBounds:YES];
	[cancelDeleteButton.layer setCornerRadius:5.0];
	[cancelDeleteButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
	[cancelDeleteButton.layer setBorderWidth: 1.0];
	[cancelDeleteButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
	[cancelDeleteButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
	
	[deleteMatchView setAlpha:0.0];
	
	[deleteMatchView setHidden:NO];
	[deleteMatchDialog setHidden:NO];
    
    [deleteMatchView setFrame:self.view.bounds];
	[self.view addSubview:deleteMatchView];
	
	[UIView beginAnimations:@"showDeleteView" context:nil];
	[UIView setAnimationDuration:0.25];
	[deleteMatchView setAlpha:1.0];
	[UIView commitAnimations];
}

- (void)hideDeleteMatchPrompt
{
    [UIView beginAnimations:@"hideDeleteView" context:nil];
	[UIView setAnimationDuration:0.25];
	[deleteMatchView setAlpha:0.0];
	[UIView commitAnimations];
    
	[deleteMatchView performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
	[deleteMatchDialog performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
	[deleteMatchView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
}

- (void)matchOptions:(id)sender
{
    id currentNode = sender;
    while(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        currentNode = [currentNode superview];
    }
    
    if(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        return;
    }
    
    self.selectedCell = currentNode;
    
    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];

    [self dismissNoResponseView];
    
    UIActionSheet *sheet;
    if([[matchData valueForKey:@"status"] isEqualToString:@"Y"])
    {
        if([[matchData valueForKey:@"muted"] boolValue] == NO)
        {
            sheet = [[UIActionSheet alloc]
                     initWithTitle:[NSString stringWithFormat:@"%@ from %@", [matchData valueForKey:@"firstName"], [matchData valueForKey:@"cityName"]]
                     delegate:self
                     cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                     destructiveButtonTitle:@"Leave Match"
                     otherButtonTitles:@"Mute", nil];
        }
        else
        {
            sheet = [[UIActionSheet alloc]
                     initWithTitle:[NSString stringWithFormat:@"%@ from %@", [matchData valueForKey:@"firstName"], [matchData valueForKey:@"cityName"]]
                     delegate:self
                     cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                     destructiveButtonTitle:@"Leave Match"
                     otherButtonTitles:@"Unmute", nil];
        }
    }
    else if([[matchData valueForKey:@"status"] isEqualToString:@"A"])
    {
        sheet = [[UIActionSheet alloc]
                 initWithTitle:@"Quick Match"
                 delegate:self
                 cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                 destructiveButtonTitle:@"Cancel Quick Match"
                 otherButtonTitles:nil];
    }
    else
    {
        if([[matchData valueForKey:@"muted"] boolValue] == NO)
        {
            sheet = [[UIActionSheet alloc]
                     initWithTitle:[NSString stringWithFormat:@"%@ from %@", [matchData valueForKey:@"firstName"], [matchData valueForKey:@"cityName"]]
                     delegate:self
                     cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                     destructiveButtonTitle:@"Delete Guide"
                     otherButtonTitles:@"Mute", nil];
        }
        else
        {
            sheet = [[UIActionSheet alloc]
                     initWithTitle:[NSString stringWithFormat:@"%@ from %@", [matchData valueForKey:@"firstName"], [matchData valueForKey:@"cityName"]]
                     delegate:self
                     cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                     destructiveButtonTitle:@"Delete Guide"
                     otherButtonTitles:@"Unmute", nil];
        }
    }

	sheet.tag = 0;
	[sheet showInView:self.view];
	[sheet release];
}

- (void)showNoResponseViewAtIndexPath:(NSIndexPath*)indexPath
{
    if(![self.noResponseView superview] && ![self.unlockPromptView superview] && ![self.extraGuideAlertView superview])
    {        
        [self.noResponseBubble.layer setMasksToBounds:YES];
        [self.noResponseBubble.layer setCornerRadius:8.0];
        
        CGRect cellFrame = [self._tableView rectForRowAtIndexPath:indexPath];
        [self.noResponseView setFrame:CGRectMake(35, cellFrame.origin.y+55, self.noResponseView.frame.size.width, self.noResponseView.frame.size.height)];
        [self._tableView addSubview:self.noResponseView];
        [self.noResponseView setAlpha:0.0];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2f];
        [self.noResponseView setAlpha:1.0];
        [UIView commitAnimations];
    }
}

- (void)showUnlockPromptViewAtIndexPath:(NSIndexPath*)indexPath
{
    if(![self.noResponseView superview] && ![self.unlockPromptView superview] && ![self.extraGuideAlertView superview])
    {
        int crossPostedPhotoCount = [appDelegate.prefs integerForKey:@"crossPostedPhotoCount"];
        int left = 3 - crossPostedPhotoCount;
        
        NSMutableAttributedString *attrStr = [NSMutableAttributedString attributedStringWithString:self.unlockPromptLabel.text];

        [attrStr setFont:self.unlockPromptLabel.font];
        [attrStr setTextColor:self.unlockPromptLabel.textColor];
        
        [attrStr setTextBold:YES range:[attrStr.string rangeOfString:@"{n}"]];
        [attrStr replaceCharactersInRange:[attrStr.string rangeOfString:@"{n}"] withString:[NSString stringWithFormat:@"%d", left]];
        
        self.unlockPromptLabel.attributedText = attrStr;
        
        [self.unlockPromptBubble.layer setMasksToBounds:YES];
        [self.unlockPromptBubble.layer setCornerRadius:8.0];
        
        CGRect cellFrame = [self._tableView rectForRowAtIndexPath:indexPath];
        [self.unlockPromptView setFrame:CGRectMake(30, cellFrame.origin.y+25, self.noResponseView.frame.size.width, self.noResponseView.frame.size.height)];
        [self._tableView addSubview:self.unlockPromptView];
        [self.unlockPromptView setAlpha:0.0];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2f];
        [self.unlockPromptView setAlpha:1.0];
        [UIView commitAnimations];
    }
}

- (void)showExtraGuideAlertViewAtIndexPath:(NSIndexPath*)indexPath
{
    int crossPostedPhotoCount = [appDelegate.prefs integerForKey:@"crossPostedPhotoCount"];

    if(![self.noResponseView superview] && ![self.unlockPromptView superview] && ![self.extraGuideAlertView superview] && crossPostedPhotoCount >= 3)
    {
        [self dismissUnlockPromptView];
        
        [self.extraGuideAlertBubble.layer setMasksToBounds:YES];
        [self.extraGuideAlertBubble.layer setCornerRadius:8.0];
        
        CGRect cellFrame = [self._tableView rectForRowAtIndexPath:indexPath];
        [self.extraGuideAlertView setFrame:CGRectMake(35, cellFrame.origin.y+25, self.noResponseView.frame.size.width, self.noResponseView.frame.size.height)];
        [self._tableView addSubview:self.extraGuideAlertView];
        [self.extraGuideAlertView setAlpha:0.0];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2f];
        [self.extraGuideAlertView setAlpha:1.0];
        [UIView commitAnimations];
    }
}

- (void)promptRating
{
    UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:NSLocalizedString(@"rateUsTitlePrompt", nil)
						  message:NSLocalizedString(@"rateUsTitleTextPrompt", nil)
						  delegate:self
						  cancelButtonTitle:NSLocalizedString(@"rateUsStopButton", nil)
						  otherButtonTitles:NSLocalizedString(@"rateUsButton", nil), NSLocalizedString(@"rateUsLaterButton", nil), nil];
    [alert setTag:99];
	[alert show];
	[alert release];
}

- (IBAction)dismissNoResponseView
{
    if([self.noResponseView superview])
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2f];
        [self.noResponseView setAlpha:0.0];
        [UIView commitAnimations];
        
        [self.noResponseView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
        
        [appDelegate.prefs setBool:YES forKey:@"didShowNoResponseView"];
        [appDelegate.prefs synchronize];
    }
}

- (IBAction)dismissUnlockPromptView
{
    if([self.unlockPromptView superview])
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2f];
        [self.unlockPromptView setAlpha:0.0];
        [UIView commitAnimations];
        
        [self.unlockPromptView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
    }
}

- (IBAction)dismissExtraGuideAlertView
{
    if([self.extraGuideAlertView superview])
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2f];
        [self.extraGuideAlertView setAlpha:0.0];
        [UIView commitAnimations];
        
        [self.extraGuideAlertView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
        
        [appDelegate.prefs setBool:YES forKey:@"didShowExtraGuideAlertView"];
        [appDelegate.prefs synchronize];
    }
}

- (IBAction)showAnnouncement:(id)sender
{
    WebViewController *webView = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    [webView setNavTitle:@"Announcement"];
    [webView setUrl:[NSString stringWithFormat:@"http://%@/mobile/announcements", appDelegate.apiHost]];
    [webView setIsModalView:YES];
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:webView];
    [self presentViewController:newNavController animated:YES completion:^(void){
        for(Announcements *announcement in appDelegate.announcements)
        {
            [(Announcements*)[appDelegate.mainMOC objectWithID:announcement.objectID] setUserChecked:[NSNumber numberWithBool:YES]];
            [appDelegate.announcements removeObject:announcement];
        }
        [appDelegate saveContext:appDelegate.mainMOC];
        tableShouldRefresh = YES;
        [self._tableView reloadData];
    }];
    [webView release];
    [newNavController release];
}

- (void)showAnnouncementAlert
{
    tableShouldRefresh = YES;
    [self._tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

#pragma mark - UITableView helpers
- (void)clearPhotoCache:(int)memberNo
{    
    NSString *memberNoString = [NSString stringWithFormat:@"%d", memberNo];
    if([photoCache objectForKey:memberNoString])
    {
        [photoCache removeObjectForKey:memberNoString];
    }
    
    NSError *error = nil;
    
    NSString *cacheImage = [NSString stringWithFormat:@"%d_45x45_memberProfile.jpg", memberNo];
    NSString *cacheImagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:cacheImage];
    bool cacheFileExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheImagePath];
    if(cacheFileExists == YES)
    {
        [[NSFileManager defaultManager] removeItemAtPath:cacheImagePath error:&error];
    }
    
    NSString *cacheImage2 = [NSString stringWithFormat:@"%d_90x90_memberProfile.jpg", memberNo];
    NSString *cacheImagePath2 = [NSTemporaryDirectory() stringByAppendingPathComponent:cacheImage2];
    bool cacheFile2Exists = [[NSFileManager defaultManager] fileExistsAtPath:cacheImagePath2];
    if(cacheFile2Exists == YES)
    {
        [[NSFileManager defaultManager] removeItemAtPath:cacheImagePath2 error:&error];
    }
}

- (void)updateNewMessageAlerts
{
    // get new message count
    if([updateMessagesOperationQueue operationCount] == 0)
    {
        CountNewMessageOperation *countNewMessageOperation = [[CountNewMessageOperation alloc] initWithMatchNo:nil];
        [countNewMessageOperation setThreadPriority:0.1];
        [updateMessagesOperationQueue addOperation:countNewMessageOperation];
        [countNewMessageOperation release];
    }
}

- (void)getThumbnail:(int)memberNo
{
    if(memberNo != 0)
	{
        // clear cache
        [self clearPhotoCache:memberNo];

        NSMutableDictionary *downloadRequestData = [[NSMutableDictionary alloc] init];
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 640] forKey:@"width"];
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 640] forKey:@"height"];
        [self.apiRequest setThreadPriority:0.1];
        [self.apiRequest getAsyncDataFromServer:@"member" withTask:@"downloadProfileImage" withData:downloadRequestData progressDelegate:nil];
        [downloadRequestData release];
        
        // reset thread priority back to default
        [self.apiRequest setThreadPriority:0.5];
    }
}

- (void)setProfileImageData:(NSDictionary*)profileImageData;
{
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    int memberNo = [[profileImageData valueForKey:@"memberNo"] intValue];
    
    NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:threadContext];
    [matchRequest setEntity:entity];
    
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"partnerNo = %d", memberNo];
	[matchRequest setPredicate:predicate];
    
	NSError *error = nil;
	NSArray *fetchedObjects = [threadContext executeFetchRequest:matchRequest error:&error];
	[matchRequest release];
    
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
	if([fetchedObjects count] > 0)
    {
        NSData *rawImageData = [profileImageData valueForKey:@"rawImageData"];
        if([rawImageData length] > 0)
        {
            // reset the cache
            NSString *memberNoString = [NSString stringWithFormat:@"%d", memberNo];
            [photoCache removeObjectForKey:memberNoString];

            NSString *imageFile = [UtilityClasses saveImageData:rawImageData named:@"memberProfile" withKey:[NSString stringWithFormat:@"%d", memberNo] overwrite:YES];
            MatchData *matchData = [fetchedObjects objectAtIndex:0];
            [matchData setValue:imageFile forKey:@"profileImage"];
            [appDelegate saveContext:threadContext];
        }
    }
}

- (void)setCacheImage:(NSDictionary*)cacheImageData
{
    int partnerNo = [[cacheImageData valueForKey:@"partnerNo"] intValue];
    int imageWidth = [[cacheImageData valueForKey:@"width"] intValue];
    int imageHeight = [[cacheImageData valueForKey:@"height"] intValue];

    NSString *cacheImage = [NSString stringWithFormat:@"%d_%dx%d_memberProfile", partnerNo, imageWidth, imageHeight];
    NSString *cacheImagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:cacheImage];
    bool cacheFileExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheImagePath];
    
    if(cacheFileExists == NO)
    {
        UIImage *image = [cacheImageData valueForKey:@"imageData"];
        UIImage *resizedImage = [image resizedImageByScalingProportionally:CGSizeMake(imageWidth, imageHeight)];
        NSData *imageData = UIImageJPEGRepresentation(resizedImage, 1.0);

        [UtilityClasses saveCacheImageData:imageData named:@"memberProfile" withKey:[NSString stringWithFormat:@"%d_%dx%d", partnerNo, imageWidth, imageHeight] overwrite:NO];
    }
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];
    int matchNo = [[matchData valueForKey:@"matchNo"] intValue];
    int partnerNo = [[matchData valueForKey:@"partnerNo"] intValue];
    NSString *partnerNoString = [NSString stringWithFormat:@"%d", partnerNo];
    
    UIView *cellView = [cell.contentView viewWithTag:0];
    
    UIImageView *profileThumbnail = (UIImageView*)[cellView viewWithTag:1];
    if([[matchData valueForKey:@"muted"] boolValue] == YES)
    {
        [profileThumbnail setAlpha:0.5];
        UILabel *mutedLabel = (UILabel*)[profileThumbnail viewWithTag:111];
        [mutedLabel setHidden:NO];
    }
    else
    {
        [profileThumbnail setAlpha:1.0];
        UILabel *mutedLabel = (UILabel*)[profileThumbnail viewWithTag:111];
        [mutedLabel setHidden:YES];
    }
    
    if([[matchData valueForKey:@"status"] isEqualToString:@"M"])
    {
        if(partnerNo == 0)
        {
            UILabel *firstNameLabel = (UILabel*)[cellView viewWithTag:2];
            //[firstNameLabel setText:@"Quick Match"];
            [firstNameLabel setText:@"New Guide"];
        }
        else
        {
            UILabel *firstNameLabel = (UILabel*)[cellView viewWithTag:2];
            [firstNameLabel setText:[matchData valueForKey:@"firstName"]];
        }
        UIImage *profileImage = [UIImage imageNamed:@"blankface45"];
        [profileThumbnail setImage:profileImage];
    }
    else
    {
        if(partnerNo == 0)
        {
            UILabel *firstNameLabel = (UILabel*)[cellView viewWithTag:2];
            //[firstNameLabel setText:@"Quick Match"];
            [firstNameLabel setText:@"New Guide"];
        }
        else
        {
            UILabel *firstNameLabel = (UILabel*)[cellView viewWithTag:2];
            [firstNameLabel setText:[matchData valueForKey:@"firstName"]];
        }
        
        bool imageIsSet = NO;
        if([photoCache objectForKey:partnerNoString])
        {
            imageIsSet = YES;
            [profileThumbnail setImage:[photoCache objectForKey:partnerNoString]];
        }
        else
        {
            NSString *profileImageFile = [matchData valueForKey:@"profileImage"];

            UIImage *placeholderImage = [UIImage imageNamed:@"blankface45.png"];
            [profileThumbnail setImage:placeholderImage];
            
            if(profileImageFile != nil && ![profileImageFile isEqualToString:@""])
            {
                UIImage *profileImage = nil;

                // if the cache is at the limit, remove one old object at a time
                if([photoCache count] >= MAX_CACHED_IMAGES)
                {
                    id oldCacheKey = [[photoCache allKeys] lastObject];
                    [photoCache removeObjectForKey:oldCacheKey];
                }
                
                if([[matchData valueForKey:@"shouldShowIntro"] boolValue] == NO)
                {
                    CUIButton *profileButton = (CUIButton*)[cell.contentView viewWithTag:11];
                    [profileButton addTarget:self action:@selector(viewProfileForMatch:) forControlEvents:UIControlEventTouchUpInside];
                }

                NSString *profileImagePath = [NSHomeDirectory() stringByAppendingPathComponent:profileImageFile];
                bool originalFileExists = [[NSFileManager defaultManager] fileExistsAtPath:profileImagePath];

                if(originalFileExists == YES)
                {
                    float imageWidth;
                    float imageHeight;
                    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
                    {
                        imageWidth = 90;
                        imageHeight = 90;
                    }
                    else
                    {
                        imageWidth = 45;
                        imageHeight = 45;
                    }
                    
                    // try to retreive cached image on disk
                    NSString *cacheImage = [NSString stringWithFormat:@"%d_%dx%d_memberProfile.jpg", partnerNo, (int)imageWidth, (int)imageHeight];
                    NSString *cacheImagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:cacheImage];
                    bool cacheFileExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheImagePath];

                    if(cacheFileExists == YES)
                    {
                        profileImage = [UIImage imageFromFile:cacheImagePath];
                    }
                    else
                    {
                        // resize profile images and add to cache
                        UIImage *originalImage = [UIImage imageFromFile:profileImagePath];
                        if(originalImage != nil)
                        {
                            // cache image to disk
                            NSMutableDictionary *cacheImageData = [[NSMutableDictionary alloc] init];
                            [cacheImageData setValue:originalImage forKey:@"imageData"];
                            [cacheImageData setValue:[NSNumber numberWithInt:partnerNo] forKey:@"partnerNo"];
                            [cacheImageData setValue:[NSNumber numberWithFloat:imageWidth] forKey:@"width"];
                            [cacheImageData setValue:[NSNumber numberWithFloat:imageHeight] forKey:@"height"];
                            
                            NSInvocationOperation *thumbOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setCacheImage:) object:cacheImageData];
                            [thumbOperation setThreadPriority:0.1];
                            [operationQueue addOperation:thumbOperation];
                            [thumbOperation release];
                            
                            [cacheImageData release];
                        }
                    }
                }

                if(profileImage != nil)
                {
                    [profileThumbnail setImage:profileImage];
                    [photoCache setObject:profileImage forKey:partnerNoString];
                    imageIsSet = YES;
                }
                else
                {
                    [self getThumbnail:partnerNo];
                }
            }
        }
        
        if(imageIsSet == YES)
        {
            CUIButton *profileButton = (CUIButton*)[cell.contentView viewWithTag:11];
            [profileButton addTarget:self action:@selector(viewProfileForMatch:) forControlEvents:UIControlEventTouchUpInside];
        }
        else
        {
            CUIButton *profileButton = (CUIButton*)[cell.contentView viewWithTag:11];
            [profileButton removeTarget:self action:@selector(viewProfileForMatch:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    UILabel *recentMessageLabel = (UILabel*)[cellView viewWithTag:3];
    UIImageView *locationIconImage = (UIImageView*)[cellView viewWithTag:22];
    UILabel *countryLabel = (UILabel*)[cellView viewWithTag:4];
    UILabel *localTimeLabel = (UILabel*)[cellView viewWithTag:40];
    UIImageView *largeLocationIcon = (UIImageView*)[cellView viewWithTag:33];
    UILabel *largeLocationLabel = (UILabel*)[cellView viewWithTag:44];
    
    if([[matchData valueForKey:@"status"] isEqualToString:@"Y"] || [[matchData valueForKey:@"status"] isEqualToString:@"N"])
    {        
        [recentMessageLabel setHidden:NO];
        [recentMessageLabel setText:[matchData valueForKey:@"recentMessage"]];
        [locationIconImage setHidden:NO];
        
        NSString *locationString = [NSString stringWithFormat:@"%@, %@", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"countryCode"]];
        UILabel *countryLabel = (UILabel*)[cellView viewWithTag:4];
        [countryLabel setHidden:NO];
        [countryLabel setText:locationString];
        
        NSTimeZone *partnerTimezone = [NSTimeZone timeZoneForSecondsFromGMT:[[matchData valueForKey:@"timezoneOffset"] intValue]];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:partnerTimezone];
        [dateFormat setDefaultDate:[NSDate date]];
        NSDate *currentTime = [dateFormat defaultDate];
        [dateFormat setDateFormat:@"h:mm a"];
        NSString *currentTimeString = [dateFormat stringFromDate:currentTime];
        [dateFormat release];
        
        [localTimeLabel setHidden:NO];
        [localTimeLabel setText:[NSString stringWithFormat:@"%@ %@", currentTimeString, [matchData valueForKey:@"timezone"]]];
        [largeLocationIcon setHidden:YES];
        [largeLocationLabel setHidden:YES];
        
        if([[matchData valueForKey:@"status"] isEqualToString:@"Y"] && [appDelegate.prefs boolForKey:@"didShowNoResponseView"] == NO && ![self.noResponseView superview] && ![self.unlockPromptView superview] && ![self.extraGuideAlertView superview])
        {
            NSTimeInterval timeZoneOffset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
            NSTimeInterval gmtTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] - timeZoneOffset;
            NSDate *gmtDate = [NSDate dateWithTimeIntervalSinceReferenceDate:gmtTimeInterval];
            
            // show no response view if current match has been unresponsive for a day
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            NSDateComponents *sessionAgeComponents = [gregorian components:NSDayCalendarUnit fromDate:matchData.matchDatetime toDate:gmtDate options:0];
            int sessionAge = [sessionAgeComponents day];
            [gregorian release];
            
            NSSet *chatData = matchData.chatData;
            
            // get received messages
            NSPredicate *receivedMessagePredicate = [NSPredicate predicateWithFormat:@"sender != %d", [appDelegate.prefs integerForKey:@"memberNo"]];
            NSSet *receivedMessages = [chatData filteredSetUsingPredicate:receivedMessagePredicate];

            if(sessionAge > 0 && matchData.matchDatetime != nil)
            {
                if([receivedMessages count] == 0)
                {
                    [self showNoResponseViewAtIndexPath:indexPath];
                }
            }
        }
    }
    else if([[matchData valueForKey:@"status"] isEqualToString:@"M"])
    {
        NSString *locationString = nil;
        if(partnerNo == 0)
        {            
            locationString = @"Somewhere in the world";
        }
        else
        {
            locationString = [NSString stringWithFormat:@"%@, %@", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"countryCode"]];
        }
        
        [recentMessageLabel setHidden:YES];
        [locationIconImage setHidden:YES];
        [countryLabel setHidden:YES];
        [largeLocationIcon setHidden:NO];
        [largeLocationIcon setImage:[UIImage imageNamed:@"ico_pippink.png"]];
        
        [largeLocationLabel setHidden:NO];
        [largeLocationLabel setText:locationString];
        [largeLocationLabel setTextColor:UIColorFromRGB(0xFF0066)];
        
        [localTimeLabel setHidden:YES];
    }
    else if([[matchData valueForKey:@"status"] isEqualToString:@"P"])
    {
        NSString *locationString = nil;
        if(partnerNo == 0)
        {            
            locationString = @"Somewhere in the world";
        }
        else
        {
            locationString = [NSString stringWithFormat:@"%@, %@", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"countryCode"]];
        }
        
        [recentMessageLabel setHidden:YES];
        [locationIconImage setHidden:YES];
        [countryLabel setHidden:YES];
        [largeLocationIcon setHidden:NO];
        [largeLocationIcon setImage:[UIImage imageNamed:@"ico_pipgray.png"]];
        
        [largeLocationLabel setHidden:NO];
        [largeLocationLabel setText:locationString];
        [largeLocationLabel setTextColor:[UIColor colorWithWhite:0.33 alpha:1.0]];
        
        [localTimeLabel setHidden:YES];
    }
    else if([[matchData valueForKey:@"status"] isEqualToString:@"A"])
    {
        NSString *locationString = @"Somewhere in the world";
        
        [recentMessageLabel setHidden:YES];
        [locationIconImage setHidden:YES];
        [countryLabel setHidden:YES];
        [largeLocationIcon setHidden:NO];
        [largeLocationIcon setImage:[UIImage imageNamed:@"ico_pipgray.png"]];
        
        [largeLocationLabel setHidden:NO];
        [largeLocationLabel setText:locationString];
        [largeLocationLabel setTextColor:[UIColor colorWithWhite:0.33 alpha:1.0]];
        
        [localTimeLabel setHidden:YES];
    }
    
    UILabel *notificationCount = (UILabel*)[cellView viewWithTag:7];
    UIView *notificationView = [cellView viewWithTag:8];
    if([[matchData valueForKey:@"update"] intValue] != 0)
    {
        [notificationView setHidden:NO];
        [notificationCount setText:[NSString stringWithFormat:@"%d", [[matchData valueForKey:@"update"] intValue]]];
    }
    else
    {
        [notificationView setHidden:YES];
        [notificationCount setText:[NSString stringWithFormat:@"%d", 0]];
    }
    
    CUIButton *settingsButton = (CUIButton*)[cellView viewWithTag:6];
    [settingsButton setHitErrorMargin:1];
    if(![[matchData valueForKey:@"status"] isEqualToString:@"M"] && ![[matchData valueForKey:@"status"] isEqualToString:@"P"] && ![[matchData valueForKey:@"status"] isEqualToString:@"Q"] && ![[matchData valueForKey:@"status"] isEqualToString:@"A"] && matchNo > 0)
    {        
        [settingsButton addTarget:self action:@selector(matchOptions:) forControlEvents:UIControlEventTouchUpInside];
        [settingsButton setBackgroundImage:[UIImage imageNamed:@"btn_rowgear"] forState:UIControlStateNormal];
        [settingsButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
        [settingsButton setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1.0] forState:UIControlStateHighlighted];
        [settingsButton setAlpha:0.15];
    }
    else
    {
        [settingsButton removeTarget:self action:@selector(matchOptions:) forControlEvents:UIControlEventTouchUpInside];
        [settingsButton setBackgroundImage:[UIImage imageNamed:@"btn_rowarrow"] forState:UIControlStateNormal];
        [settingsButton setAlpha:0.15];
    }
    
    if([loadingCells containsObject:indexPath])
    {
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[cellView viewWithTag:5];
        CUIButton *settingsButton = (CUIButton*)[cell viewWithTag:6];
        [spinner startAnimating];
        [settingsButton setHidden:YES];
    }
    else
    {
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[cellView viewWithTag:5];
        CUIButton *settingsButton = (CUIButton*)[cell viewWithTag:6];
        [spinner stopAnimating];
        [settingsButton setHidden:NO];
    }
}

#pragma mark - IBActions
- (IBAction)showProfile
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"touchCompleteProfile"];
    
	ProfileViewController *profileController = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController" bundle:nil];
	profileController.isModalView = YES;
	UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:profileController];
	[self presentModalViewController:newNavController animated:YES];
	[profileController release];
	[newNavController release];
}

- (IBAction)getMatch:(id)sender
{
    if([[appDelegate.prefs valueForKey:@"suspended"] isEqualToString:@"Y"])
    {
        NSDictionary *alertData = [[NSDictionary alloc] initWithObjectsAndKeys:@"Start Wandering!", @"title", @"You must disable the 'Stop Wandering' setting in your Guide Match Options before you can search for new guides.", @"message", nil];
        [appDelegate displayAlert:alertData];
        [alertData release];
        return;
    }
    int matchLimit = [appDelegate.prefs integerForKey:@"matchLimit"];
    int newSessionCount = [[self todaysNewSessions:appDelegate.mainMOC] count];
    int pendingSessionCount = [[self pendingSessions:appDelegate.mainMOC] count];
    int currentSessionCount = [[self currentSessions:appDelegate.mainMOC] count];
    int crossPostedPhotoCount = [appDelegate.prefs integerForKey:@"crossPostedPhotoCount"];
    
    if(crossPostedPhotoCount < 3 && matchLimit <= newSessionCount+pendingSessionCount+currentSessionCount)
    {
        if([sender isKindOfClass:[NSDictionary class]])
        {
            NSIndexPath *indexPath = (NSIndexPath*)[sender valueForKey:@"indexPath"];
            [self showUnlockPromptViewAtIndexPath:indexPath];
            return;
        }
    }
    
	if(appDelegate.networkStatus == NO)
	{
		return;
	}
    
    if(isSearching == YES)
    {
        return;
    }
    
    if(isFirstRun == YES)
    {
        isFirstRun = NO;
    }
    
    isSearching = YES;
    [self showSearchIndicator];

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"touchGetMatch"];    

    UpdateMatchListOperation *updateMatchOperation = [[UpdateMatchListOperation alloc] init];
    [updateMatchOperation setThreadPriority:1.0];
    [requestOperationQueue addOperation:updateMatchOperation];
    [updateMatchOperation release];

    AddMatchOperation *addMatchOperation = [[AddMatchOperation alloc] init];
    [addMatchOperation setThreadPriority:1.0];
    [requestOperationQueue addOperation:addMatchOperation];
    [addMatchOperation release];
}

- (IBAction)didTouchCancelLeave
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"cancelLeaveMatch"];    
	[self hideLeaveAlert];
}

- (IBAction)didTouchConfirmLeave
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"confirmLeaveMatch"];

    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];

    [matchData setValue:@"N" forKey:@"status"];
    [matchData setValue:[NSNumber numberWithBool:NO] forKey:@"open"];
    [matchData setValue:[NSNumber numberWithInt:4] forKey:@"order"];
    [matchData setValue:[UtilityClasses currentUTCDate] forKey:@"expireDate"];
    [appDelegate saveContext:appDelegate.mainMOC];

    [self hideLeaveAlert];
    
    NSInvocationOperation *declineOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(exitMatch:) object:matchData];
    [declineOperation setThreadPriority:1.0];
    [requestOperationQueue addOperation:declineOperation];
    [declineOperation release];
    
    FeedbackViewController *feedbackController = [[FeedbackViewController alloc] initWithNibName:@"FeedbackViewController" bundle:nil];
    [feedbackController setMatchData:matchData];
    [feedbackController setDeclinedMatchNo:[[matchData valueForKey:@"matchNo"] intValue]];
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:feedbackController];
    
    [self presentModalViewController:newNavController animated:YES];
    
    CGRect navBarFrame = [[newNavController navigationBar] frame];
    CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, navBarFrame.size.height + 10);
    [[newNavController navigationBar] resizeBGLayer:newFrame];
    [[newNavController navigationBar] setCaption:NSLocalizedString(@"feedbackCaption", nil)];
    
    [feedbackController release];
    [newNavController release];
}

- (IBAction)didConfirmDumped
{
	[self hideDumpedAlert];
	[appDelegate.prefs setInteger:0 forKey:@"wasDumped"];
	[appDelegate.prefs setValue:nil forKey:@"wasDumpedBy"];
    [self._tableView reloadData];
}

- (IBAction)didCancelStop
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"cancelStopQuickMatch"];
	[self hideStopQuickMatchPrompt];
}

- (IBAction)didConfirmStop
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"confirmStopQuickMatch"];

    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];

    UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self.selectedCell viewWithTag:5];
    CUIButton *settingsButton = (CUIButton*)[self.selectedCell viewWithTag:6];
    [settingsButton setHidden:YES];
    [spinner startAnimating];

    NSNumber *matchNo = [matchData valueForKey:@"matchNo"];
    [loadingCells addObject:matchNo];
    
	[self hideStopQuickMatchPrompt];
    
    CancelQuickMatchOperation *cancelQuickMatchOperation = [[CancelQuickMatchOperation alloc] init];
    [cancelQuickMatchOperation setThreadPriority:1.0];
    [requestOperationQueue addOperation:cancelQuickMatchOperation];
    [cancelQuickMatchOperation release];
    
    [self._tableView reloadData];
}

- (IBAction)didCancelDelete
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"cancelDeleteMatch"];
    
    [self hideDeleteMatchPrompt];
}

- (IBAction)didConfirmDelete
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"confirmDeleteMatch"];
    
    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];
    
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self.selectedCell viewWithTag:5];
    CUIButton *settingsButton = (CUIButton*)[self.selectedCell viewWithTag:6];
    [settingsButton setHidden:YES];
    [spinner startAnimating];

    NSNumber *matchNo = [matchData valueForKey:@"matchNo"];
    [loadingCells addObject:matchNo];
    
    NSInvocationOperation *deleteOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(deleteMatch:) object:[matchData objectID]];
    [deleteOperation setThreadPriority:1.0];
    [requestOperationQueue addOperation:deleteOperation];
    [deleteOperation release];
    
    [self hideDeleteMatchPrompt];
}

#pragma mark - match related core data helpers
- (void)clearInvalidMatches
{
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    // delete pending matches that have expired
    NSError *error = nil;
    NSFetchRequest *invalidMatchData = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:threadContext];
    [invalidMatchData setEntity:entity];

    // remove fake matches and old quick matches (-1 and -2)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(matchNo > 0 AND (status = 'M' OR status = 'P') AND activeDate != %@) OR matchNo = nil OR matchNo = -1 OR matchNo = -2 OR (matchNo = 0 and activeDate != %@)", [UtilityClasses currentUTCDate], [UtilityClasses currentUTCDate]];
    [invalidMatchData setPredicate:predicate];
    [invalidMatchData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *invalidMatchArray = [threadContext executeFetchRequest:invalidMatchData error:&error];
    [invalidMatchData release];
    
    for (NSManagedObject *match in invalidMatchArray)
    {
        [threadContext deleteObject:match];
    }
    
    // renew status for expired matches
    NSFetchRequest *expiredMatchData = [[NSFetchRequest alloc] init];
    [expiredMatchData setEntity:entity];

    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"matchNo > 0 AND status != 'D' AND expireDate < %@", [UtilityClasses currentUTCDate]];
    [expiredMatchData setPredicate:predicate2];
    NSArray *expiredMatchArray = [threadContext executeFetchRequest:expiredMatchData error:&error];
    [expiredMatchData release];
    for(MatchData *match in expiredMatchArray)
    {
        [match setValue:@"N" forKey:@"status"];
        [match setValue:[NSNumber numberWithInt:4] forKey:@"order"];
    }
    
    // save
    [appDelegate saveContext:threadContext];
}

- (void)clearBlankRows
{
	NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:appDelegate.mainMOC];
    [matchRequest setEntity:entity];
    
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = 0"];
	[matchRequest setPredicate:predicate];
    [matchRequest setIncludesPropertyValues:NO];
    
	NSError *error = nil;
	NSArray *fetchedObjects = [appDelegate.mainMOC executeFetchRequest:matchRequest error:&error];
	[matchRequest release];
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
	for(MatchData *matchData in fetchedObjects)
	{
		[appDelegate.mainMOC deleteObject:matchData];
	}
	[appDelegate saveContext:appDelegate.mainMOC];
}

- (void)checkLatestMatch
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    MatchData *latestMatch = [self getRecentMatchData:threadContext];

	if(latestMatch != nil)
    {        
        if(![[latestMatch valueForKey:@"status"] isEqualToString:@"Y"])
        {
            NSDate *lastExpireDate = [latestMatch valueForKey:@"expireDate"];
            NSTimeInterval interval = [[UtilityClasses currentUTCDate] timeIntervalSinceDate:lastExpireDate];
            
            // update shouldRequestNewMatch after 2 days of no matches
            if(interval > (86400 * 2))
            {
                // should search for new match
                [appDelegate.prefs setValue:[NSNumber numberWithBool:NO] forKey:@"shouldRequestNewMatch"];
                [appDelegate.prefs synchronize];
            }
        }
    }

    [pool drain];
}

- (MatchData*)getRecentMatchData:(NSManagedObjectContext*)passedContext
{
	NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:passedContext];
    [matchRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo != 0"];
	[matchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescripter = [[NSSortDescriptor alloc] initWithKey:@"expireDate" ascending:NO];
	NSArray *sortDescripters = [[NSArray alloc] initWithObjects:sortDescripter, nil];
	[matchRequest setSortDescriptors:sortDescripters];
	[sortDescripters release];
	[sortDescripter release];
    
    [matchRequest setFetchLimit:1];
    
	NSError *error = nil;
	NSArray *fetchedObjects = [passedContext executeFetchRequest:matchRequest error:&error];
	[matchRequest release];
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
	if([fetchedObjects count] > 0)
    {
        MatchData *currentMatch = [fetchedObjects objectAtIndex:0];
        return currentMatch;
    }
    else
    {
        return nil;
    }
}

- (NSArray*)todaysNewSessions:(NSManagedObjectContext*)passedContext
{
	NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:passedContext];
    [matchRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = 'M'"];
	[matchRequest setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [passedContext executeFetchRequest:matchRequest error:&error];
	[matchRequest release];
	
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
    NSMutableArray *sessionArray = [[NSMutableArray alloc] init];
    for(MatchData *newSession in fetchedObjects)
    {
        [sessionArray addObject:[newSession valueForKey:@"matchNo"]];
    }
    
    return [sessionArray autorelease];
}

- (NSArray*)pendingSessions:(NSManagedObjectContext*)passedContext
{
	NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:passedContext];
    [matchRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = 'M' OR status = 'P' OR status = 'A'"];
	[matchRequest setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [passedContext executeFetchRequest:matchRequest error:&error];
	[matchRequest release];
	
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
    NSMutableArray *sessionArray = [[NSMutableArray alloc] init];
    for(MatchData *pendingSession in fetchedObjects)
    {
        [sessionArray addObject:[pendingSession valueForKey:@"matchNo"]];
    }

    return [sessionArray autorelease];
}

- (NSArray*)currentSessions:(NSManagedObjectContext*)passedContext
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:passedContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = 'Y' AND expireDate >= %@", [UtilityClasses currentUTCDate]];
    [request setPredicate:predicate];
    [request setIncludesPropertyValues:NO];

    NSError *error = nil;
	NSArray *fetchedObjects = [passedContext executeFetchRequest:request error:&error];
	[request release];
	
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
    NSMutableArray *sessionArray = [[NSMutableArray alloc] init];
    for(MatchData *currentSession in fetchedObjects)
    {
        [sessionArray addObject:currentSession];
    }

    return [sessionArray autorelease];
}

- (NSArray*)expiredSessions:(NSManagedObjectContext*)passedContext
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:passedContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(matchNo > 0 and status != 'D' and expireDate < %@) OR status = 'N'", [UtilityClasses currentUTCDate]];
    [request setPredicate:predicate];
    [request setIncludesPropertyValues:NO];
    
    NSError *error = nil;
	NSArray *fetchedObjects = [passedContext executeFetchRequest:request error:&error];
	[request release];
	
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
    NSMutableArray *sessionArray = [[NSMutableArray alloc] init];
    for(MatchData *currentSession in fetchedObjects)
    {
        [sessionArray addObject:currentSession];
    }
    
    return [sessionArray autorelease];
}

- (NSArray*)todaysDeclinedSessions:(NSManagedObjectContext*)passedContext
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:passedContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = 'X' AND regDatetime = %@", [UtilityClasses currentUTCDate]];
    [request setPredicate:predicate];
    [request setIncludesPropertyValues:NO];
    
    NSError *error = nil;
	NSArray *fetchedObjects = [passedContext executeFetchRequest:request error:&error];
	[request release];
	
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
    NSMutableArray *sessionArray = [[NSMutableArray alloc] init];
    for(MatchData *currentSession in fetchedObjects)
    {
        [sessionArray addObject:[currentSession valueForKey:@"matchNo"]];
    }
    
    return [sessionArray autorelease];
}

- (bool)hasPendingQuickMatch:(NSManagedObjectContext*)passedContext
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:passedContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = 'A'"];
    [request setPredicate:predicate];
    [request setIncludesPropertyValues:NO];
    
    NSError *error = nil;
    int currentSessions = [passedContext countForFetchRequest:request error:&error];
    [request release];
    
    if(currentSessions == 0)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)declineAllMatches
{
	// send decline request to server
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
	[memberData setValue:@"N" forKey:@"wasDeclined"];
	[self.apiRequest sendServerRequest:@"match" withTask:@"declineAllMatches" withData:memberData];
	[memberData release];
}

- (void)exitMatch:(MatchData*)matchData
{
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    MatchData *declinedMatchData = (MatchData*)[threadContext objectWithID:[matchData objectID]];
    
	// send decline request to server
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
    [memberData setValue:[NSString stringWithFormat:@"%d", [[declinedMatchData valueForKey:@"partnerNo"] intValue]] forKey:@"partnerNo"];
    [memberData setValue:[NSString stringWithFormat:@"%d", [[declinedMatchData valueForKey:@"matchNo"] intValue]] forKey:@"matchNo"];

	[self.apiRequest sendServerRequest:@"match" withTask:@"exitMatch" withData:memberData];
	[memberData release];
}

- (void)muteMatch:(NSManagedObjectID*)objectID
{
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

	// send mute request to server
    MatchData *matchData = (MatchData*)[threadContext objectWithID:objectID];
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
    [memberData setValue:[NSString stringWithFormat:@"%d", [[matchData valueForKey:@"matchNo"] intValue]] forKey:@"matchNo"];
	NSDictionary *result = [self.apiRequest sendServerRequest:@"match" withTask:@"muteMatch" withData:memberData];
	[memberData release];
    
    if(result)
    {
        if([[result valueForKey:@"numRows"] intValue] > 0)
        {
            [self performSelectorOnMainThread:@selector(doneMutingMatch:) withObject:objectID waitUntilDone:NO];
        }
    }
}

- (void)doneMutingMatch:(NSManagedObjectID*)objectID
{
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self.selectedCell viewWithTag:5];
    CUIButton *settingsButton = (CUIButton*)[self.selectedCell viewWithTag:6];
    [settingsButton setHidden:NO];
    [spinner stopAnimating];

    MatchData *matchData = (MatchData*)[appDelegate.mainMOC objectWithID:objectID];
    [matchData setValue:[NSNumber numberWithBool:YES] forKey:@"muted"];
    [appDelegate saveContext:appDelegate.mainMOC];
    
    NSNumber *matchNo = [matchData valueForKey:@"matchNo"];
    [loadingCells removeObject:matchNo];
}

- (void)unmuteMatch:(NSManagedObjectID*)objectID
{
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

	// send mute request to server
    MatchData *matchData = (MatchData*)[threadContext objectWithID:objectID];
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
    [memberData setValue:[NSString stringWithFormat:@"%d", [[matchData valueForKey:@"matchNo"] intValue]] forKey:@"matchNo"];
	NSDictionary *result = [self.apiRequest sendServerRequest:@"match" withTask:@"unmuteMatch" withData:memberData];
	[memberData release];
    
    if(result)
    {
        if([result valueForKey:@"numRows"] != nil && [result valueForKey:@"numRows"] != [NSNull null])
        {
            [self performSelectorOnMainThread:@selector(doneUnmutingMatch:) withObject:objectID waitUntilDone:NO];
        }
    }
}

- (void)doneUnmutingMatch:(NSManagedObjectID*)objectID
{
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self.selectedCell viewWithTag:5];
    CUIButton *settingsButton = (CUIButton*)[self.selectedCell viewWithTag:6];
    [settingsButton setHidden:NO];
    [spinner stopAnimating];

    MatchData *matchData = (MatchData*)[appDelegate.mainMOC objectWithID:objectID];
    [matchData setValue:[NSNumber numberWithBool:NO] forKey:@"muted"];
    [appDelegate saveContext:appDelegate.mainMOC];
    
    NSNumber *matchNo = [matchData valueForKey:@"matchNo"];
    [loadingCells removeObject:matchNo];
}

- (void)deleteMatch:(NSManagedObjectID*)objectID
{
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    // send mute request to server
    MatchData *matchData = (MatchData*)[threadContext objectWithID:objectID];

	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
    [memberData setValue:[matchData valueForKey:@"partnerNo"] forKey:@"partnerNo"];
    [memberData setValue:[NSString stringWithFormat:@"%d", [[matchData valueForKey:@"matchNo"] intValue]] forKey:@"matchNo"];
	NSDictionary *result = [self.apiRequest sendServerRequest:@"match" withTask:@"deleteMatch" withData:memberData];
	[memberData release];
    
    if(result)
    {
        if([result valueForKey:@"numRows"] != nil && [result valueForKey:@"numRows"] != [NSNull null])
        {
            [self performSelectorOnMainThread:@selector(doneDeletingMatch:) withObject:objectID waitUntilDone:NO];
        }
    }
}

- (void)doneDeletingMatch:(NSManagedObjectID*)objectID
{
    MatchData *matchData = (MatchData*)[appDelegate.mainMOC objectWithID:objectID];
    [matchData setValue:@"D" forKey:@"status"];
    [appDelegate saveContext:appDelegate.mainMOC];
}

// update match list
- (void)updateMatchListData
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
        return;
    }

    if([updateMatchesOperationQueue operationCount] == 0)
    {
        UpdateMatchListOperation *updateMatchOperation = [[UpdateMatchListOperation alloc] init];
        [updateMatchOperation setThreadPriority:0.1];
        [updateMatchesOperationQueue addOperation:updateMatchOperation];
        [updateMatchOperation release];
    }
}

- (void)setFindGuideRow
{
    int newSessionCount = [[self todaysNewSessions:appDelegate.mainMOC] count];
    int pendingSessionCount = [[self pendingSessions:appDelegate.mainMOC] count];
    int currentSessionCount = [[self currentSessions:appDelegate.mainMOC] count];
    int expiredSessionCount = [[self expiredSessions:appDelegate.mainMOC] count];
    int maxMatchCount = [appDelegate.prefs integerForKey:@"maxMatchCount"];

    NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:appDelegate.mainMOC];
    [matchRequest setEntity:entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = -100"];
	[matchRequest setPredicate:predicate];

	NSError *error = nil;
    NSArray *buttonRows = [appDelegate.mainMOC executeFetchRequest:matchRequest error:&error];

    if((pendingSessionCount == 0 && currentSessionCount == 0 && expiredSessionCount == 0) || newSessionCount > 0 || isSearching == YES)
    {
        if([buttonRows count] > 0)
        {
            [self dismissExtraGuideAlertView];

            MatchData *buttonRow = [buttonRows objectAtIndex:0];
            [appDelegate.mainMOC deleteObject:buttonRow];
            [appDelegate saveContext:appDelegate.mainMOC];
        }
    }
    else if(currentSessionCount + pendingSessionCount < maxMatchCount)
    {
        if([buttonRows count] == 0)
        {
            NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"MatchData" inManagedObjectContext:appDelegate.mainMOC];
            
            // set matchNo
            [newManagedObject setValue:[NSNumber numberWithInt:-100] forKey:@"matchNo"];

            [newManagedObject setValue:[NSNumber numberWithInt:1] forKey:@"order"];
            [newManagedObject setValue:@"F" forKey:@"status"];

            // set required data
            [newManagedObject setValue:@"" forKey:@"firstName"];
            [newManagedObject setValue:[NSNumber numberWithInt:0] forKey:@"partnerNo"];
            
            // save data
            [appDelegate saveContext:appDelegate.mainMOC];
        }
    }
    [matchRequest release];
}

#pragma mark - navigation
- (void)goToChatScreen:(MatchData*)matchData animated:(bool)animated
{
    NewChatViewController *newChatViewController = [[NewChatViewController alloc] initWithNibName:@"NewChatViewController" bundle:nil];
    [newChatViewController setMatchNo:[[matchData valueForKey:@"matchNo"] intValue]];
    [newChatViewController setMatchData:matchData];
    if([[matchData valueForKey:@"status"] isEqualToString:@"N"])
	{
        bool open = [[matchData valueForKey:@"open"] boolValue];
        if(open == YES)
        {
            [newChatViewController setChatDisabled:NO];
        }
        else
        {
            [newChatViewController setChatDisabled:YES];
        }
	}
	else
	{
		[newChatViewController setChatDisabled:NO];
	}
	[appDelegate.mainNavController pushViewController:newChatViewController animated:animated];
    [newChatViewController release];
    
	[appDelegate hideLoading];
}

- (void)goToPartnerIntro:(MatchData*)matchData animated:(bool)animated
{
    MatchIntroViewController *matchIntroController = [[MatchIntroViewController alloc] initWithNibName:@"MatchIntroViewController" bundle:nil];
    [matchIntroController setMatchData:matchData];
    [appDelegate.mainNavController pushViewController:matchIntroController animated:YES];
    [matchIntroController release];
}

- (void)viewProfileForMatch:(id)sender
{
    id currentNode = sender;
    while(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        currentNode = [currentNode superview];
    }
    
    if(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        return;
    }
    
    self.selectedCell = currentNode;
    
    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];

    if([[matchData valueForKey:@"latitude"] floatValue] == 0 && [[matchData valueForKey:@"longitude"] floatValue] == 0)
    {
        // if longitude and latitude are 0 gecode city and country
        NSString *locationString = nil;
        if([[matchData valueForKey:@"provinceCode"] isEqualToString:@""] || [matchData valueForKey:@"provinceCode"] == nil)
        {
            locationString = [NSString stringWithFormat:@"%@,%@", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"countryName"]];
        }
        else
        {
            locationString = [NSString stringWithFormat:@"%@,%@,%@", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"provinceCode"], [matchData valueForKey:@"countryName"]];
        }
        
        CLLocationCoordinate2D coords = [UtilityClasses geocode:locationString];
        [matchData setValue:[NSNumber numberWithFloat:coords.latitude] forKey:@"latitude"];
        [matchData setValue:[NSNumber numberWithFloat:coords.longitude] forKey:@"longitude"];
        [appDelegate saveContext:appDelegate.mainMOC];
    }
    
    MatchIntroViewController *matchIntroController = [[MatchIntroViewController alloc] initWithNibName:@"MatchIntroViewController" bundle:nil];
    matchIntroController.isModalView = YES;
    matchIntroController.matchData = matchData;
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:matchIntroController];
    [self presentModalViewController:newNavController animated:YES];
    [newNavController release];
    [matchIntroController release];
}

- (void)openSettings
{
	SettingsViewController *settingsController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
	UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:settingsController];
	[newNavController.view setBackgroundColor:[UIColor blackColor]];
	[[newNavController navigationBar] setBackgroundColor:[UIColor blackColor]];
	[self presentModalViewController:newNavController animated:YES];
	[newNavController release];
	[settingsController release];
}

- (void)loadChatView:(NSIndexPath*)indexPath
{
	int sectionType = [[[[self.resultsController sections] objectAtIndex:indexPath.section] name] intValue];
	MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];
    
    if([[matchData valueForKey:@"latitude"] floatValue] == 0 && [[matchData valueForKey:@"longitude"] floatValue] == 0)
    {
        // if longitude and latitude are 0 gecode city and country
        NSString *locationString = nil;
        if([[matchData valueForKey:@"provinceCode"] isEqualToString:@""] || [matchData valueForKey:@"provinceCode"] == nil)
        {
            locationString = [NSString stringWithFormat:@"%@,%@", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"countryName"]];
        }
        else
        {
            locationString = [NSString stringWithFormat:@"%@,%@,%@", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"provinceCode"], [matchData valueForKey:@"countryName"]];
        }
        
        CLLocationCoordinate2D coords = [UtilityClasses geocode:locationString];
        [matchData setValue:[NSNumber numberWithFloat:coords.latitude] forKey:@"latitude"];
        [matchData setValue:[NSNumber numberWithFloat:coords.longitude] forKey:@"longitude"];
        [appDelegate saveContext:appDelegate.mainMOC];
    }
    
    if(sectionType == 1)
	{
        if([[matchData valueForKey:@"shouldShowIntro"] boolValue] == NO)
        {
            [self goToChatScreen:matchData animated:YES];
        }
        else
        {
            [self goToPartnerIntro:matchData animated:YES];
        }
	}
	else if(sectionType == 3 || sectionType == 2)
	{
        if([[matchData valueForKey:@"partnerNo"] intValue] == 0)
        {
            QuickMatchViewController *quickMatchViewController = [[QuickMatchViewController alloc] initWithNibName:@"QuickMatchViewController" bundle:nil];
            [quickMatchViewController setMatchData:matchData];
            [appDelegate.mainNavController pushViewController:quickMatchViewController animated:YES];
            [quickMatchViewController release];
        }
        else
        {
            // wait up to 2.5 seconds until profile photo is downloaded
            int retryCount = 0;
            [appDelegate.mainMOC refreshObject:matchData mergeChanges:YES];
            while([matchData valueForKey:@"profileImage"] == nil && retryCount < 25)
            {
                retryCount = retryCount + 1;
                [NSThread sleepForTimeInterval:0.1];
            }
            
            // start new match controller
            NewMatchViewController *newMatchController = [[NewMatchViewController alloc] initWithNibName:@"NewMatchViewController" bundle:nil];
            newMatchController.matchNo = [[matchData valueForKey:@"matchNo"] intValue];
            newMatchController.matchData = matchData;
            [appDelegate.mainNavController pushViewController:newMatchController animated:YES];
            [newMatchController release];
        }
	}
	else
	{
		[self goToChatScreen:matchData animated:YES];
	}
	
	UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[cell viewWithTag:5];
    CUIButton *settingsButton = (CUIButton*)[cell viewWithTag:6];
	[spinner stopAnimating];
	[settingsButton setHidden:NO];
	isLoadingChat = NO;
    [loadingCells removeObject:indexPath];
}

#pragma mark - APIRequest delegate
- (void)didReceiveBinary:(NSData*)data andHeaders:(NSDictionary*)headers
{
    // if task was download photo get message number
    int memberNo = [[headers objectForKey:@"X-Yongopal-Memberno"] intValue];

    // hand over downloaded photo
    NSDictionary *photoData = [[NSDictionary alloc] initWithObjectsAndKeys:
                               data, @"rawImageData",
                               [NSNumber numberWithInt:memberNo], @"memberNo", nil];

    NSInvocationOperation *thumbOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setProfileImageData:) object:photoData];
    [thumbOperation setThreadPriority:0.1];
    [operationQueue addOperation:thumbOperation];
    [thumbOperation release];
    [photoData release];
}

#pragma mark - table cells
- (UIView*)getMatchCell
{
    UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 75)];
    [cell setBackgroundColor:[UIColor whiteColor]];

    CUIButton *profileButton = [[CUIButton alloc] initWithFrame:CGRectMake(12, 16, 45, 45)];
    [profileButton setBackgroundColor:[UIColor clearColor]];
    [profileButton setTag:11];
    [profileButton setHitErrorMargin:1];
    
    UIImage *placeholderImage = [UIImage imageNamed:@"blankthumb.png"];
    UIImageView *profileThumbnail = [[UIImageView alloc] initWithImage:placeholderImage];
    [profileThumbnail setFrame:CGRectMake(12, 16, 45, 45)];
    [profileThumbnail.layer setMasksToBounds:YES];
    [profileThumbnail.layer setCornerRadius:5];
    [profileThumbnail setTag:1];

    UILabel *mutedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 31, 45, 14)];
    [mutedLabel setText:@"Muted"];
    [mutedLabel setTextColor:UIColorFromRGB(0xFF0066)];
    [mutedLabel setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:10.5]];
    [mutedLabel setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
    [mutedLabel setTextAlignment:UITextAlignmentCenter];
    [mutedLabel setTag:111];
    [mutedLabel setHidden:YES];
    [profileThumbnail addSubview:mutedLabel];
    [mutedLabel release];
    
    UILabel *firstNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(67, 15, 148, 20)];
    [firstNameLabel setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:20.0]];
    [firstNameLabel setTextColor:[UIColor blackColor]];
    [firstNameLabel setTag:2];

    UILabel *recentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(67, 33, 198, 17)];
    [recentMessageLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:12.0]];
    [recentMessageLabel setTextColor:[UIColor colorWithWhite:0.33 alpha:1.0]];
    [recentMessageLabel setTag:3];
    
    UIImage *locationIconImage = [UIImage imageNamed:@"ico_locationgray.png"];
    UIImageView *locationIcon = [[UIImageView alloc] initWithImage:locationIconImage];
    [locationIcon setFrame:CGRectMake(67, 54, 8, 12)];
    [locationIcon setTag:22];

    UIImage *largeLocationIconImage = [UIImage imageNamed:@"ico_pippink.png"];
    UIImageView *largeLocationIcon = [[UIImageView alloc] initWithImage:largeLocationIconImage];
    [largeLocationIcon setFrame:CGRectMake(67, 43, 9, 14)];
    [largeLocationIcon setTag:33];
    
    UILabel *largeLocationLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 42, 150, 20)];
    [largeLocationLabel setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:15.0]];
    [largeLocationLabel setTextColor:UIColorFromRGB(0xFF0066)];
    [largeLocationLabel setTag:44];

    UILabel *countryLabel = [[UILabel alloc] initWithFrame:CGRectMake(78, 52, 117, 15)];
    [countryLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:11.0]];
    [countryLabel setTextColor:[UIColor colorWithWhite:0.67 alpha:1.0]];
    [countryLabel setTag:4];
    
    UILabel *localTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 52, 85, 15)];
    [localTimeLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:11.0]];
    [localTimeLabel setTextColor:[UIColor colorWithWhite:0.67 alpha:1.0]];
    [localTimeLabel setTextAlignment:UITextAlignmentRight];
    [localTimeLabel setTag:40];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(281, 27, 20, 20)];
    [spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [spinner stopAnimating];
    [spinner setTag:5];
    
    CUIButton *settingsButton = [[CUIButton alloc] initWithFrame:CGRectMake(273, 20, 35, 35)];
    [settingsButton setTag:6];

    UIImage *notificationIconImage = [UIImage imageNamed:@"notify_chat.png"];
    UIImageView *notificationIcon = [[UIImageView alloc] initWithImage:notificationIconImage];
    [notificationIcon setFrame:CGRectMake(0, 0, 20, 20)];

    UILabel *notificationCount = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 19, 18)];
    [notificationCount setOpaque:NO];
    [notificationCount setFont:[UIFont fontWithName:NSLocalizedString(@"boldFont", nil) size:11.0]];
    [notificationCount setText:[NSString stringWithFormat:@"%d", 0]];
    [notificationCount setTextAlignment:UITextAlignmentCenter];
    [notificationCount setBackgroundColor:[UIColor clearColor]];
    [notificationCount setTextColor:[UIColor whiteColor]];
    [notificationCount setTag:7];

    UIView *notificationView = [[UIView alloc] initWithFrame:CGRectMake(44, 7, 20, 20)];
    [notificationView setTag:8];
    [notificationView addSubview:notificationIcon];
    [notificationView addSubview:notificationCount];
    [notificationIcon release];
    [notificationCount release];

    [cell addSubview:profileButton];
    [cell addSubview:profileThumbnail];
    [cell addSubview:firstNameLabel];
    [cell addSubview:recentMessageLabel];
    [cell addSubview:locationIcon];
    [cell addSubview:countryLabel];
    [cell addSubview:localTimeLabel];
    [cell addSubview:largeLocationIcon];
    [cell addSubview:largeLocationLabel];
    [cell addSubview:spinner];
    [cell addSubview:settingsButton];
    [cell addSubview:notificationView];
    
    [profileButton release];
    [profileThumbnail release];
    [firstNameLabel release];
    [recentMessageLabel release];
    [locationIcon release];
    [largeLocationIcon release];
    [largeLocationLabel release];
    [countryLabel release];
    [localTimeLabel release];
    [spinner release];
    [settingsButton release];
    [notificationView release];

    return [cell autorelease];
}

- (UIView*)getBlankCell
{
    UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 75)];
    [cell setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 75)];
    [textLabel setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [textLabel setBackgroundColor:[UIColor clearColor]];
    [textLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:13.0]];
    [textLabel setTextColor:[UIColor colorWithWhite:0.4 alpha:1.0]];
    [textLabel setLineBreakMode:UILineBreakModeWordWrap];
    [textLabel setNumberOfLines:999];
    [textLabel setTag:1];
    [cell addSubview:textLabel];
    [textLabel release];
    
    return [cell autorelease];
}

- (UIView*)getRequestMatchButtonCell
{
    UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 32)];
    [cell setBackgroundColor:[UIColor blackColor]];

    UIButton *requestButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 300, 32)];
    [requestButton setUserInteractionEnabled:NO];
    [requestButton setTag:10];
    [requestButton addTarget:self action:@selector(getMatch:) forControlEvents:UIControlEventTouchUpInside];
    [requestButton setBackgroundImage:[UIImage imageNamed:@"bg_AddBar.png"] forState:UIControlStateNormal];
    [cell addSubview:requestButton];
    [requestButton release];
    
    UIImage *plusImage = [UIImage imageNamed:@"btn_Add.png"];
    UIImageView *plusImageView = [[UIImageView alloc] initWithImage:plusImage];
    [plusImageView setFrame:CGRectMake(285, 10, 13, 13)];
    [cell addSubview:plusImageView];
    [plusImageView release];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 275, 30)];
    [textLabel setTag:20];
    [textLabel setTextAlignment:UITextAlignmentRight];
    [textLabel setText:@"Find Guide"];
    [textLabel setBackgroundColor:[UIColor clearColor]];
    [textLabel setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:15.0f]];
    [textLabel setTextColor:[UIColor whiteColor]];
    [cell addSubview:textLabel];
    [textLabel release];
    
    return [cell autorelease];
}

- (UIView*)getAnnounceButtonCell
{
    UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 32)];
    [cell setBackgroundColor:[UIColor blackColor]];
    
    UIButton *requestButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 300, 32)];
    [requestButton setUserInteractionEnabled:NO];
    [requestButton setTag:10];
    [requestButton addTarget:self action:@selector(showAnnouncement:) forControlEvents:UIControlEventTouchUpInside];
    [requestButton setBackgroundImage:[UIImage imageNamed:@"bg_AnnounceBar.png"] forState:UIControlStateNormal];
    [cell addSubview:requestButton];
    [requestButton release];
    
    UIImage *plusImage = [UIImage imageNamed:@"124-bullhorn.png"];
    UIImageView *plusImageView = [[UIImageView alloc] initWithImage:plusImage];
    [plusImageView setFrame:CGRectMake(285, 10, 18, 13)];
    [cell addSubview:plusImageView];
    [plusImageView release];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 275, 30)];
    [textLabel setTag:20];
    [textLabel setTextAlignment:UITextAlignmentRight];
    [textLabel setText:@"Wander Announcement"];
    [textLabel setBackgroundColor:[UIColor clearColor]];
    [textLabel setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:15.0f]];
    [textLabel setTextColor:[UIColor whiteColor]];
    [cell addSubview:textLabel];
    [textLabel release];
    
    return [cell autorelease];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[self.resultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];

    if([[matchData valueForKey:@"matchNo"] intValue] == -100)
    {
        static NSString *CellIdentifier = @"RequestNewMatchCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

        UIView *cellView = nil;
		if (cell == nil || tableShouldRefresh == YES)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            [cell.layer setShadowColor:[[UIColor colorWithWhite:0.6 alpha:1.0] CGColor]];
            [cell.layer setShadowOffset:CGSizeMake(0.0f, 1.0f)];
            [cell.layer setShadowOpacity:1.0f];
            [cell.layer setShadowRadius:0.0f];
            [cell setClipsToBounds:NO];

            UITableViewCell *bgView = [[UITableViewCell alloc] initWithFrame:CGRectZero];
            bgView.backgroundColor = UIColorFromRGB(0x000000);
            cell.backgroundView = bgView;
            [bgView release];
            
            [cell setUserInteractionEnabled:YES];
            
            if([appDelegate.announcements count] > 0)
            {
                cellView = [self getAnnounceButtonCell];
            }
            else
            {
                cellView = [self getRequestMatchButtonCell];
            }

            [cellView setTag:0];
            [cell.contentView addSubview:cellView];
            
            tableShouldRefresh = NO;
        }
        else
        {
            cellView = [cell.contentView viewWithTag:0];
        }

        UILabel *buttonLabel = (UILabel*)[cellView viewWithTag:20];
        if([appDelegate.announcements count] > 0)
        {
            [buttonLabel setText:@"Wander Announcement"];
        }
        else
        {
            if([[[self.resultsController sections] objectAtIndex:indexPath.section] numberOfObjects] > 1)
            {
                [buttonLabel setText:@"Add Guide"];
            }
            else
            {
                [buttonLabel setText:@"Find Guide"];
            }
        }
        
        if([appDelegate.prefs boolForKey:@"didShowExtraGuideAlertView"] == NO)
        {
            [self showExtraGuideAlertViewAtIndexPath:indexPath];
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

        return cell;
    }
	else if(![[matchData valueForKey:@"status"] isEqualToString:@"E"])
	{
        static NSString *CellIdentifier = @"MatchCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

        UIView *cellView = nil;
		if (cell == nil)
        {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cellView = [self getMatchCell];
            [cellView.layer setShadowColor:[[UIColor colorWithWhite:0.6 alpha:1.0] CGColor]];
            [cellView.layer setShadowOffset:CGSizeMake(0.0f, 1.0f)];
            [cellView.layer setShadowOpacity:1.0f];
            [cellView.layer setShadowRadius:0.0f];
            [cellView setClipsToBounds:NO];
            [cellView setTag:0];
            [cell.contentView addSubview:cellView];
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];

            UITableViewCell *selectedView = [[UITableViewCell alloc] initWithFrame:CGRectZero];
            selectedView.backgroundColor = UIColorFromRGB(0xECECEC);
            cell.selectedBackgroundView = selectedView;
            [selectedView release];

            UITableViewCell *bgView = [[UITableViewCell alloc] initWithFrame:CGRectZero];
            bgView.backgroundColor = UIColorFromRGB(0xFFFFFF);
            cell.backgroundView = bgView;
            [bgView release];
            
            // show disclosure icon
            [[cellView viewWithTag:6] setHidden:NO];
		}

		// Configure the cell...
        [self configureCell:cell atIndexPath:indexPath];

		return cell;
	}
	else
	{
        static NSString *CellIdentifier = @"BlankCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        UIView *cellView = nil;
		if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            [cell.layer setShadowColor:[[UIColor colorWithWhite:0.6 alpha:1.0] CGColor]];
            [cell.layer setShadowOffset:CGSizeMake(0.0f, 1.0f)];
            [cell.layer setShadowOpacity:1.0f];
            [cell.layer setShadowRadius:0.0f];
            [cell setClipsToBounds:NO];
            
            cellView = [self getBlankCell];
            [cellView setTag:0];
            [cell.contentView addSubview:cellView];
            
            UITableViewCell *bgView = [[UITableViewCell alloc] initWithFrame:CGRectZero];
            bgView.backgroundColor = UIColorFromRGB(0xFFFFFF);
            cell.backgroundView = bgView;
            [bgView release];

            [cell setUserInteractionEnabled:YES];
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        }
        else
        {
            cellView = [cell.contentView viewWithTag:0];
        }

        UILabel *cellText = (UILabel*)[cellView viewWithTag:1];
		if([[matchData valueForKey:@"order"] intValue] == -1)
        {
            NSString *text = NSLocalizedString(@"noMatchAvailableText", nil);
            CGSize textSize = {300.0f, 99999.0f};
            CGSize size = [text sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:13.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];

            [cellText setText:NSLocalizedString(@"noMatchAvailableText", nil)];
            [cellView setFrame:CGRectMake(0, 0, 320, size.height+26)];
        }
        else
        {
            NSString *text = NSLocalizedString(@"wereSearchingTheGlobeText", nil);
            CGSize textSize = {300.0f, 99999.0f};
            CGSize size = [text sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:13.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];

            [cellText setText:NSLocalizedString(@"wereSearchingTheGlobeText", nil)];
            [cellView setFrame:CGRectMake(0, 0, 320, size.height+26)];
        }
		
		return cell;
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	int sectionType = [[[[self.resultsController sections] objectAtIndex:section] name] intValue];

	UILabel *headerTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 7, 300, 16)];
	UIImageView *headerImage = nil;

    if(sectionType == -3)
    {
        headerTitle.text = NSLocalizedString(@"quickMatchHeader", nil);
		headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_pink.png"]];
    }
    else if(sectionType == -2)
    {
        headerTitle.text = NSLocalizedString(@"pendingQuickMatchHeader", nil);
		headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_pending.png"]];
    }
    else if(sectionType == -1)
    {
        headerTitle.text = NSLocalizedString(@"noMatchAvailableHeader", nil);
		headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_pending.png"]];
    }
	else if(sectionType == 0)
	{
		headerTitle.text = NSLocalizedString(@"matchRequestSentHeader", nil);
		headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_pending.png"]];
	}
	else if(sectionType == 2)
	{
		headerTitle.text = NSLocalizedString(@"newGuideHeader", nil);
		headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_pink.png"]];
	}
	else if(sectionType == 1)
	{
		headerTitle.text = NSLocalizedString(@"currentGuideHeader", nil);
		headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_blue.png"]];
	}
	else if(sectionType == 3)
	{
		headerTitle.text = NSLocalizedString(@"waitingForMatchHeader", nil);
		headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_pending.png"]];
	}
	else if(sectionType == 4)
	{
		headerTitle.text = NSLocalizedString(@"pastGuidesHeader", nil);
		headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_gray.png"]];
	}

	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 27)];
    header.backgroundColor = [UIColor clearColor];
	[header addSubview:headerImage];
    [headerImage release];

	[headerTitle setFont:[UIFont fontWithName:NSLocalizedString(@"extraBoldFont", nil) size:15.0f]];
    [headerTitle setBackgroundColor:[UIColor clearColor]];
    [headerTitle setTextColor:[UIColor whiteColor]];
	[header addSubview:headerTitle];
	[headerTitle release];

    return [header autorelease];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	float result = 76;

    int sectionType = [[[[self.resultsController sections] objectAtIndex:indexPath.section] name] intValue];
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];

    if(sectionType == -1)
    {
        NSString *text = NSLocalizedString(@"noMatchAvailableText", nil);
        CGSize textSize = {300.0f, 99999.0f};
		CGSize size = [text sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:13.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];

        if(size.height > 76)
        {
            result = size.height + 26;
        }
    }
    else if(sectionType == 0)
    {
        NSString *text = NSLocalizedString(@"wereSearchingTheGlobeText", nil);
        CGSize textSize = {300.0f, 99999.0f};
		CGSize size = [text sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:13.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
        
        if(size.height > 76)
        {
            result = size.height + 26;
        }
    }
    else if([[matchData valueForKey:@"matchNo"] intValue] == -100)
    {
        result = 32;
    }
    
	return result;
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
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];
    
    if([[matchData valueForKey:@"matchNo"] intValue] == -100)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIView *cellView = [cell.contentView viewWithTag:0];
        UIButton *buttonImageView = (UIButton*)[cellView viewWithTag:10];
        [buttonImageView setHighlighted:YES];
    }
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];

    if([[matchData valueForKey:@"matchNo"] intValue] == 0)
    {
        [self clearBlankRows];
    }
    else if([[matchData valueForKey:@"matchNo"] intValue] == -100)
    {
        if([appDelegate.announcements count] > 0)
        {
            [self showAnnouncement:nil];
        }
        else
        {
            [self getMatch:[NSDictionary dictionaryWithObject:indexPath forKey:@"indexPath"]];
        }

        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIView *cellView = [cell.contentView viewWithTag:0];
        UIButton *buttonImageView = (UIButton*)[cellView viewWithTag:10];
        [buttonImageView performSelector:@selector(setHighlighted:) withObject:NO afterDelay:0.1];
    }
	else if(isLoadingChat == NO && [[matchData valueForKey:@"matchNo"] intValue] != -100)
	{
		isLoadingChat = YES;
		
		UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[cell viewWithTag:5];
        CUIButton *settingsButton = (CUIButton*)[cell viewWithTag:6];
        [settingsButton setHidden:YES];
		[spinner startAnimating];

        [loadingCells addObject:indexPath];
		[self performSelector:@selector(loadChatView:) withObject:indexPath afterDelay:0.1];
	}
}

#pragma mark - fetched results controller delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self._tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self._tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationTop];
            break;

        case NSFetchedResultsChangeDelete:
            [self._tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationTop];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath 
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [loadingCells removeObject:indexPath];
            [self._tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            break;

        case NSFetchedResultsChangeDelete:
            [loadingCells removeObject:indexPath];
            [self._tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
            break;

        case NSFetchedResultsChangeUpdate:
            [self configureCell:[_tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;

        case NSFetchedResultsChangeMove:
            [self._tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self._tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self._tableView endUpdates];
    [self performSelectorOnMainThread:@selector(setFindGuideRow) withObject:nil waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(updateMatchView) withObject:nil waitUntilDone:NO];
}

- (void)downloadThumbnail:(NSNotification *)notification
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:NO];
        return;
    }
    
    NSDictionary *data = [notification userInfo];
    int memberNo = [[data valueForKey:@"memberNo"] intValue];
    [self getThumbnail:memberNo];
}

- (void)shouldShowDumpedAlert:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    [self performSelectorOnMainThread:@selector(showDumpedAlert:) withObject:[data valueForKey:@"firstName"] waitUntilDone:NO];
}

- (void)shouldShowSearchIndicator:(NSNotification *)notification
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:NO];
        return;
    }

    [self showSearchIndicator];
    [self setFindGuideRow];
}

- (void)shouldHideSearchIndicator:(NSNotification *)notification
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:NO];
        return;
    }

    [self hideSearchIndicator];
    [self setFindGuideRow];
}

#pragma mark - action sheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
    MatchData *matchData = [self.resultsController objectAtIndexPath:indexPath];
    
    if([[matchData valueForKey:@"status"] isEqualToString:@"Y"])
    {
        if(buttonIndex == 0)
        {
            NSTimeInterval timeZoneOffset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
            NSTimeInterval gmtTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] - timeZoneOffset;
            NSDate *gmtDate = [NSDate dateWithTimeIntervalSinceReferenceDate:gmtTimeInterval];
            
            // show no response view if current match has been unresponsive for a day
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            NSDateComponents *sessionAgeComponents = [gregorian components:NSDayCalendarUnit fromDate:matchData.matchDatetime toDate:gmtDate options:0];
            int sessionAge = [sessionAgeComponents day];
            [gregorian release];
            
            NSSet *chatData = matchData.chatData;
            
            // get received messages
            NSPredicate *receivedMessagePredicate = [NSPredicate predicateWithFormat:@"sender != %d", [appDelegate.prefs integerForKey:@"memberNo"]];
            NSSet *receivedMessages = [chatData filteredSetUsingPredicate:receivedMessagePredicate];

            // users are not allowed to leave matches on the first day if they haven't received anything
            if((sessionAge > 0 && matchData.matchDatetime != nil) || [receivedMessages count] > 0) 
            {
                [self showLeaveAlert];
            }
            else
            {
                NSDictionary *alertData = [[NSDictionary alloc] initWithObjectsAndKeys:NSLocalizedString(@"cantLeaveMatchPrompt", nil), @"title", NSLocalizedString(@"cantLeaveMatchTextPrompt", nil), @"message", nil];
                [appDelegate displayAlert:alertData];
                [alertData release];
            }
        }
        else if(buttonIndex == 1)
        {
            UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self.selectedCell viewWithTag:5];
            CUIButton *settingsButton = (CUIButton*)[self.selectedCell viewWithTag:6];
            [settingsButton setHidden:YES];
            [spinner startAnimating];

            NSNumber *matchNo = [matchData valueForKey:@"matchNo"];
            [loadingCells addObject:matchNo];
            
            if([[matchData valueForKey:@"muted"] boolValue] == NO)
            {
                NSInvocationOperation *muteOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(muteMatch:) object:[matchData objectID]];
                [muteOperation setThreadPriority:1.0];
                [requestOperationQueue addOperation:muteOperation];
                [muteOperation release];
            }
            else
            {
                NSInvocationOperation *muteOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(unmuteMatch:) object:[matchData objectID]];
                [muteOperation setThreadPriority:1.0];
                [requestOperationQueue addOperation:muteOperation];
                [muteOperation release];
            }
        }
    }
    else if([[matchData valueForKey:@"status"] isEqualToString:@"A"])
    {
        if(buttonIndex == 0)
        {
            [self showStopQuickMatchPrompt];
        }
    }
    else
    {
        if(buttonIndex == 0)
        {
            [self showDeleteMatchPrompt];
        }
        else if(buttonIndex == 1)
        {
            UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self.selectedCell viewWithTag:5];
            CUIButton *settingsButton = (CUIButton*)[self.selectedCell viewWithTag:6];
            [settingsButton setHidden:YES];
            [spinner startAnimating];

            NSNumber *matchNo = [matchData valueForKey:@"matchNo"];
            [loadingCells addObject:matchNo];

            if([[matchData valueForKey:@"muted"] boolValue] == NO)
            {
                NSInvocationOperation *muteOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(muteMatch:) object:[matchData objectID]];
                [muteOperation setThreadPriority:1.0];
                [requestOperationQueue addOperation:muteOperation];
                [muteOperation release];
            }
            else
            {
                NSInvocationOperation *muteOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(unmuteMatch:) object:[matchData objectID]];
                [muteOperation setThreadPriority:1.0];
                [requestOperationQueue addOperation:muteOperation];
                [muteOperation release];
            }
        }
    }
    
}

#pragma mark - alertView delegate
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(actionSheet.tag == 99)
	{
        if(buttonIndex == 0)
        {
            [appDelegate.prefs setBool:YES forKey:@"didRateApp"];
            [appDelegate.prefs synchronize];
        }
        else if(buttonIndex == 1)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=449594244"]];

            [appDelegate.prefs setBool:YES forKey:@"didRateApp"];
            [appDelegate.prefs synchronize];
        }
        else
        {
            NSTimeInterval timeZoneOffset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
            NSTimeInterval gmtTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate] - timeZoneOffset;

            [appDelegate.prefs setFloat:gmtTimeInterval forKey:@"remindToRateApp"];
            [appDelegate.prefs synchronize];
        }
	}
}

@end
