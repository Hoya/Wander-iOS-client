//
//  MatchListViewController.h
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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "YongoPalAppDelegate.h"
#import "NewChatViewController.h"
#import "SettingsViewController.h"
#import "NewMatchViewController.h"
#import "CUIButton.h"

@interface MatchListViewController : UIViewController
<
	UITableViewDataSource,
	UITableViewDelegate,
	NSFetchedResultsControllerDelegate,
    UIActionSheetDelegate,
    UIAlertViewDelegate,
    APIRequestDelegate
>
{
	YongoPalAppDelegate *appDelegate;
    APIRequest *apiRequest;

	UITableView *_tableView;
	UIView *getMatchView;
	UIView *completeProfileView;
    UIView *noResponseView;
    UIView *noResponseBubble;
    UIView *unlockPromptView;
    UIView *unlockPromptBubble;
    OHAttributedLabel *unlockPromptLabel;
    UIView *extraGuideAlertView;
    UIView *extraGuideAlertBubble;
	NSFetchedResultsController *resultsController;
    NSMutableDictionary *photoCache;
    NSMutableArray *loadingCells;
    
    NSMutableArray *matchNumberArray;

    NSOperationQueue *updateMatchesOperationQueue;
    NSOperationQueue *updateMessagesOperationQueue;
    NSOperationQueue *requestOperationQueue;
	NSOperationQueue *operationQueue;
	
	UIView *modalView;
	UIView *leaveAlert;
	UITextView *leaveAlertMessage;
	CUIButton *cancelLeave;
	CUIButton *confirmLeave;
    
    UIView *stopQuickMatchView;
    UIView *stopQuickMatchDialog;
    CUIButton *cancelStopButton;
	CUIButton *confirmStopButton;
    
    UIView *deleteMatchView;
    UIView *deleteMatchDialog;
    CUIButton *cancelDeleteButton;
	CUIButton *confirmDeleteButton;
	
	UIView *modalView2;
	UIView *dumpedAlert;
	UITextView *dumpedAlertMessage;
	CUIButton *confirmDumped;
	
	UIView *searchIndicator;

    NSTimer *timer;
    UITableViewCell *selectedCell;
	
	bool isLoadingChat;
	bool isUpdatingMatches;
    bool isFirstRun;
    bool isSearching;
    bool shouldReloadTableData;
    bool tableShouldRefresh;
}

@property (nonatomic, retain) APIRequest *apiRequest;
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) IBOutlet UITableView *_tableView;
@property (nonatomic, retain) IBOutlet UIView *getMatchView;
@property (nonatomic, retain) IBOutlet UIView *completeProfileView;
@property (nonatomic, retain) IBOutlet UIView *noResponseView;
@property (nonatomic, retain) IBOutlet UIView *noResponseBubble;
@property (nonatomic, retain) IBOutlet UIView *unlockPromptView;
@property (nonatomic, retain) IBOutlet UIView *unlockPromptBubble;
@property (nonatomic, retain) IBOutlet OHAttributedLabel *unlockPromptLabel;
@property (nonatomic, retain) IBOutlet UIView *extraGuideAlertView;
@property (nonatomic, retain) IBOutlet UIView *extraGuideAlertBubble;
@property (nonatomic, retain) IBOutlet UIView *modalView;
@property (nonatomic, retain) IBOutlet UIView *leaveAlert;
@property (nonatomic, retain) IBOutlet UITextView *leaveAlertMessage;
@property (nonatomic, retain) IBOutlet CUIButton *cancelLeave;
@property (nonatomic, retain) IBOutlet CUIButton *confirmLeave;
@property (nonatomic, retain) IBOutlet UIView *stopQuickMatchView;
@property (nonatomic, retain) IBOutlet UIView *stopQuickMatchDialog;
@property (nonatomic, retain) IBOutlet CUIButton *cancelStopButton;
@property (nonatomic, retain) IBOutlet CUIButton *confirmStopButton;
@property (nonatomic, retain) IBOutlet UIView *deleteMatchView;
@property (nonatomic, retain) IBOutlet UIView *deleteMatchDialog;
@property (nonatomic, retain) IBOutlet CUIButton *cancelDeleteButton;
@property (nonatomic, retain) IBOutlet CUIButton *confirmDeleteButton;
@property (nonatomic, retain) IBOutlet UIView *modalView2;
@property (nonatomic, retain) IBOutlet UIView *dumpedAlert;
@property (nonatomic, retain) IBOutlet UITextView *dumpedAlertMessage;
@property (nonatomic, retain) IBOutlet CUIButton *confirmDumped;
@property (nonatomic, retain) IBOutlet UIView *searchIndicator;
@property (nonatomic, readwrite) bool isFirstRun;
@property (nonatomic, readwrite) bool shouldReloadTableData;
@property (nonatomic, assign) UITableViewCell *selectedCell;
@property (nonatomic, retain) NSTimer *timer;

// main UI methods
- (void)updateMatchView;
- (void)setProfileThumbnail;
- (void)showSearchIndicator;
- (void)hideSearchIndicator;
- (void)showLeaveAlert;
- (void)hideLeaveAlert;
- (void)showDumpedAlert:(NSString*)firstName;
- (void)hideDumpedAlert;
- (void)showGetMatchView;
- (void)showCompleteProfileView;
- (void)showStopQuickMatchPrompt;
- (void)hideStopQuickMatchPrompt;
- (void)showDeleteMatchPrompt;
- (void)hideDeleteMatchPrompt;
- (void)matchOptions:(id)sender;
- (void)showNoResponseViewAtIndexPath:(NSIndexPath*)indexPath;
- (void)showUnlockPromptViewAtIndexPath:(NSIndexPath*)indexPath;
- (void)showExtraGuideAlertViewAtIndexPath:(NSIndexPath*)indexPath;
- (void)promptRating;
- (IBAction)dismissNoResponseView;
- (IBAction)dismissUnlockPromptView;
- (IBAction)dismissExtraGuideAlertView;
- (IBAction)showAnnouncement:(id)sender;
- (void)showAnnouncementAlert;

// UITableView helpers
- (void)clearPhotoCache:(int)memberNo;
- (void)updateNewMessageAlerts;
- (void)getThumbnail:(int)memberNo;
- (void)setProfileImageData:(NSDictionary*)profileImageData;
- (void)setCacheImage:(NSDictionary*)cacheImageData;
- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

// IBActions
- (IBAction)showProfile;
- (IBAction)getMatch:(id)sender;
- (IBAction)didTouchCancelLeave;
- (IBAction)didTouchConfirmLeave;
- (IBAction)didConfirmDumped;
- (IBAction)didCancelStop;
- (IBAction)didConfirmStop;
- (IBAction)didCancelDelete;
- (IBAction)didConfirmDelete;

// match related core data helpers
- (void)clearInvalidMatches;
- (void)clearBlankRows;
- (void)checkLatestMatch;
- (MatchData*)getRecentMatchData:(NSManagedObjectContext*)passedContext;
- (NSArray*)todaysNewSessions:(NSManagedObjectContext*)passedContext;
- (NSArray*)pendingSessions:(NSManagedObjectContext*)passedContext;
- (NSArray*)currentSessions:(NSManagedObjectContext*)passedContext;
- (NSArray*)expiredSessions:(NSManagedObjectContext*)passedContext;
- (NSArray*)todaysDeclinedSessions:(NSManagedObjectContext*)passedContext;
- (bool)hasPendingQuickMatch:(NSManagedObjectContext*)passedContext;
- (void)declineAllMatches;
- (void)exitMatch:(MatchData*)matchData;
- (void)muteMatch:(NSManagedObjectID*)objectID;
- (void)doneMutingMatch:(NSManagedObjectID*)objectID;
- (void)unmuteMatch:(NSManagedObjectID*)objectID;
- (void)doneUnmutingMatch:(NSManagedObjectID*)objectID;
- (void)deleteMatch:(NSManagedObjectID*)objectID;
- (void)doneDeletingMatch:(NSManagedObjectID*)objectID;
- (void)updateMatchListData;
- (void)setFindGuideRow;

// navigation
- (void)goToChatScreen:(MatchData*)matchData animated:(bool)animated;
- (void)goToPartnerIntro:(MatchData*)matchData animated:(bool)animated;
- (void)viewProfileForMatch:(id)sender;
- (void)openSettings;
- (void)loadChatView:(NSIndexPath*)indexPath;

// MOC helpers & notification handlers
- (void)downloadThumbnail:(NSNotification *)notification;
- (void)shouldShowDumpedAlert:(NSNotification *)notification;
- (void)shouldShowSearchIndicator:(NSNotification *)notification;
- (void)shouldHideSearchIndicator:(NSNotification *)notification;

// table cells
- (UIView*)getMatchCell;
- (UIView*)getBlankCell;
- (UIView*)getRequestMatchButtonCell;
- (UIView*)getAnnounceButtonCell;

@end