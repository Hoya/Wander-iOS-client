//
//  NewChatViewController.m
//  Wander
//
//  Created by Jiho Kang on 10/6/11.
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

#import "NewChatViewController.h"

#import "MatchIntroViewController.h"
#import "TweetViewController.h"

#import "CheckNewMessageOperation.h"
#import "QueueMessageOperation.h"
#import "SendMessageOperation.h"
#import "QueuePhotoOperation.h"
#import "ConfirmSentOperation.h"
#import "ReceiveMessageOperation.h"

#import "TranslationData.h"

#import "NSString+HTML.h"

@implementation NewChatViewController
@synthesize matchData;
@synthesize shareController;
@synthesize selectedKey;
@synthesize lastIndexPath;

@synthesize fetchedResultsController=_fetchedResultsController;
@synthesize apiRequest;
@synthesize photoCache=_photoCache;
@synthesize photoDataCache=_photoDataCache;
@synthesize operationQueue;
@synthesize translateOperationQueue;
@synthesize syncOperationQueue;
@synthesize sendOperationQueue;
@synthesize receiveOperationQueue;
@synthesize twitter=_twitter;
@synthesize facebook;

@synthesize userProfileImage=_userProfileImage;
@synthesize partnerProfileImage=_partnerProfileImage;

@synthesize spool;
@synthesize uploadPool;
@synthesize resendPool;
@synthesize downloadPool;
@synthesize retryPool;
@synthesize translationPool;
@synthesize translatedMessages;
@synthesize facebookSharePool;
@synthesize twitterSharePool;
@synthesize twitterQueue;

@synthesize _tableView;
@synthesize loadMoreView;
@synthesize loadMoreLabel;
@synthesize loadingLabel;
@synthesize loadingSpinner;
@synthesize chatInput;
@synthesize chatInputContainer;
@synthesize chatBarView;
@synthesize chatBar;
@synthesize sendButton;
@synthesize shareSomething;
@synthesize welcomeView;
@synthesize welcomePrompt;
@synthesize welcomeTitle;
@synthesize closeWelcomePromptButton;
@synthesize takePhotoButton;

@synthesize translatePromptView;
@synthesize translatePromptBubble;
@synthesize sharePromptView;
@synthesize sharePromptBubble;

@synthesize selectedCell;

@synthesize matchNo;
@synthesize showIntroPrompt;
@synthesize chatDisabled;

#define MAX_CACHED_IMAGES 15

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        shouldScrollToBottom = YES;
        maxListItems = 25;
        
        self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.operationQueue setMaxConcurrentOperationCount:4];
        
        self.translateOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.translateOperationQueue setMaxConcurrentOperationCount:1];
        
        self.syncOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.syncOperationQueue setMaxConcurrentOperationCount:1];
        
        self.sendOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.sendOperationQueue setMaxConcurrentOperationCount:1];
        
        self.receiveOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.receiveOperationQueue setMaxConcurrentOperationCount:1];
        
        self.apiRequest = [[[APIRequest alloc] init] autorelease];
        [self.apiRequest setThreadPriority:0.8];
        [self.apiRequest setDelegate:self];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(sendMessageToServer:) name:@"shouldSendMessageToServer" object:nil];
        [dnc addObserver:self selector:@selector(confirmSentMessages:) name:@"shouldConfirmSentMessage" object:nil];
        [dnc addObserver:self selector:@selector(checkNewMessages:) name:@"shouldCheckNewMessages" object:nil];
        [dnc addObserver:self selector:@selector(getNewMessages:) name:@"shouldGetNewMessages" object:nil];
        [dnc addObserver:self selector:@selector(updatePartnerData:) name:@"shouldUpdatePartnerData" object:nil];
        [dnc addObserver:self selector:@selector(setSentPhotoThumbnail:) name:@"shouldSetThumbnail" object:nil];
        
        [dnc addObserver:self selector:@selector(addKeyToTextPool:) name:@"shouldAddToTextPool" object:nil];
        [dnc addObserver:self selector:@selector(addKeyToUploadPool:) name:@"shouldAddToUploadPool" object:nil];
        [dnc addObserver:self selector:@selector(removeKey:) name:@"shouldRemoveKey" object:nil];
        
        [dnc addObserver:self selector:@selector(postToFBWithKey:) name:@"shouldPostToFB" object:nil];
        [dnc addObserver:self selector:@selector(tweetWithKey:) name:@"shouldTweet" object:nil];
        
        [dnc addObserver:self selector:@selector(scrollToBottomAnimated:) name:@"shouldScrollToBottomAnimated" object:nil];
        [dnc addObserver:self selector:@selector(reloadTableData:) name:@"shouldReloadTableData" object:nil];
        [dnc addObserver:self selector:@selector(dismissModalView:) name:@"shouldDismissModalView" object:nil];
        
        [dnc addObserver:self selector:@selector(setPhotoCache:) name:@"shouldSetPhotoCache" object:nil];
        [dnc addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
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
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // resize the navbar
    CGRect navBarFrame = [[self.navigationController navigationBar] frame];
    CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, 54);
    [[self.navigationController navigationBar] resizeBGLayer:newFrame];

    // set title
    [self.navigationItem setCustomTitle:[self.matchData valueForKey:@"firstName"]];

    #if TARGET_IPHONE_SIMULATOR
    UIButton *debugButton = (UIButton*)[[self.navigationItem titleView] viewWithTag:1];
    [debugButton addTarget:self action:@selector(checkNewMessages:) forControlEvents:UIControlEventTouchUpInside];
    #endif

    // fetch chat data
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
	}

    // set navigation buttons
    UIImage *backImage = [UIImage imageNamed:@"btn_back.png"];
    CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
    CUIButton *backButton = [[CUIButton alloc] initWithFrame:backFrame];
    [backButton setImage:backImage forState:UIControlStateNormal];
    [backButton setShowsTouchWhenHighlighted:YES];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backBarButtonItem];
    [backBarButtonItem release];
    [backButton release];

    // set multi-line / autoresizing text view
    HPGrowingTextView *aTextView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(0, 0, 190, 25)];
    [aTextView setClipsToBounds:YES];
    [aTextView.layer setMasksToBounds:YES];
    [aTextView.layer setCornerRadius:4];
    [aTextView setMinNumberOfLines:1];
    [aTextView setMaxNumberOfLines:3];
    [aTextView setReturnKeyType:UIReturnKeyDefault];
    [aTextView setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:15.0f]];
    [aTextView.internalTextView setBackgroundColor:[UIColor whiteColor]];
    [aTextView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin];
    self.chatInput = aTextView;
    [chatInputContainer addSubview:chatInput];

    float y = ((chatInputContainer.frame.size.height - chatInput.frame.size.height) / 2) - 1;
    [chatInputContainer setFrame:CGRectMake(chatInputContainer.frame.origin.x, y, chatInputContainer.frame.size.width, chatInput.frame.size.height)];
    [chatInput sizeToFit];

    [aTextView release];
    
    UIView *shadowContainer = [chatBarView viewWithTag:1];
    [shadowContainer setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_chatshadow"]]];
    [shadowContainer.layer setOpaque:NO];
    shadowContainer.opaque = NO;
    
    [self.loadMoreView setFrame:CGRectMake(0, -30, 320, 30)];
    [self.loadMoreLabel setHidden:NO];
    [self.loadingLabel setHidden:YES];
    [self.loadingSpinner stopAnimating];
    [self._tableView addSubview:self.loadMoreView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStateChanged:) name:YPSessionStateChangedNotification object:nil];

    [self setMissionsButton];

    if(chatDisabled == NO)
    {
        navbarTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(setTimeForHeader) userInfo:nil repeats:YES];
    }
    
    if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)
    {
        CGRect tableFrame = self._tableView.frame;
        [UIView beginAnimations:@"hideLocalTime" context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [self._tableView setFrame:CGRectMake(tableFrame.origin.x, 0, tableFrame.size.width, self.view.frame.size.height)];
        [UIView commitAnimations];
    }
    else
    {
        CGRect tableFrame = self._tableView.frame;
        [UIView beginAnimations:@"showLocalTime" context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [self._tableView setFrame:CGRectMake(tableFrame.origin.x, 10, tableFrame.size.width, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES]-10)];
        [UIView commitAnimations];
    }

    // show/hide background image guides
	if([[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects] != 0 || chatDisabled == YES)
	{
		[shareSomething setHidden:YES];
	}
	else
	{
		[shareSomething setHidden:NO];
	}

    // show archive if chat is disabled
    if(![[matchData valueForKey:@"status"] isEqualToString:@"Y"])
    {
        [self.navigationItem setRightBarButtonItem:nil];
    }

	if(chatDisabled == YES)
	{
		if(chatBarView.hidden == NO)
		{
			CGRect newTableFrame = self._tableView.frame;
			newTableFrame.size.height += chatBarView.frame.size.height;
			_tableView.frame = newTableFrame;
			[chatBarView setHidden:YES];
		}
		[[self.navigationController navigationBar] setCaption:NSLocalizedString(@"archiveCaption", nil)];
	}
	else
	{
		if(chatBarView.hidden == YES)
		{
			CGRect newTableFrame = self._tableView.frame;
			newTableFrame.size.height -= chatBarView.frame.size.height;
			_tableView.frame = newTableFrame;
			[chatBarView setHidden:NO];
		}
        [navbarTimer fire];
	}

	// scroll to last row
    if(shouldScrollToBottom == YES)
    {
        [self performSelectorOnMainThread:@selector(scrollToBottomWithAnimation:) withObject:NO waitUntilDone:NO];
    }
    else if(self.lastIndexPath != nil)
    {
        [self performSelectorOnMainThread:@selector(scrollToIndexPath:) withObject:self.lastIndexPath waitUntilDone:NO];
    }
    
    [appDelegate hideLoading];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"chatViewDidAppear"];

	[super viewDidAppear:animated];

    if(shouldLoadTweet == YES)
    {
        NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
        ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self newTweetForObjectID:[chatData objectID]];
    }
    
    // show welcome prompt
    [self showWelcomeView];

    // check for new messages
    CheckNewMessageOperation *checkMessageOperation = [[CheckNewMessageOperation alloc] initWithMatchData:matchData];
    [checkMessageOperation setThreadPriority:0.1];
    [self.syncOperationQueue addOperation:checkMessageOperation];
    [checkMessageOperation release];
    
    [self.chatInput setDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [chatInput resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    NSArray *visableIndexPaths = [self._tableView indexPathsForVisibleRows];
    
    if([visableIndexPaths count] != 0)
    {
        self.lastIndexPath = [visableIndexPaths lastObject];
    }
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [navbarTimer invalidate];
    navbarTimer = nil;
    [self.chatInput setDelegate:nil];

    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YPSessionStateChangedNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.welcomeView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.translatePromptView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.sharePromptView];

    [_photoCache removeAllObjects];
    [_photoDataCache removeAllObjects];
    
    self.selectedKey = nil;

    [self._tableView setDelegate:nil];
    self._tableView = nil;
    self.loadMoreView = nil;
    self.loadMoreLabel = nil;
    self.loadingLabel = nil;
    self.loadingSpinner = nil;
    self.chatInput = nil;
    self.chatInputContainer = nil;
    self.chatBarView = nil;
    self.chatBar = nil;
    self.sendButton = nil;
    self.welcomeView = nil;
    self.welcomePrompt = nil;
    self.welcomeTitle = nil;
    self.closeWelcomePromptButton = nil;
    self.takePhotoButton = nil;
    
    self.facebook = nil;
    
    self.translatePromptView = nil;
    self.translatePromptBubble = nil;
    self.sharePromptView = nil;
    self.sharePromptBubble = nil;

    self.userProfileImage = nil;
    self.partnerProfileImage = nil;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.welcomeView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.translatePromptView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.sharePromptView];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.matchData = nil;
    self.shareController = nil;

    [_fetchedResultsController setDelegate:nil];
    [_fetchedResultsController release];
    [apiRequest release];
    [_photoCache release];
    [_photoDataCache release];
    
    [operationQueue cancelAllOperations];
    [translateOperationQueue cancelAllOperations];
    [syncOperationQueue cancelAllOperations];
    [sendOperationQueue cancelAllOperations];
    [receiveOperationQueue cancelAllOperations];

    [operationQueue release];
    [translateOperationQueue release];
    [syncOperationQueue release];
    [sendOperationQueue release];
    [receiveOperationQueue release];

    [_twitter release];
    [facebook release];

    [self._tableView setDelegate:nil];
    self._tableView = nil;
    self.loadMoreLabel = nil;
    self.loadingLabel = nil;
    self.loadingSpinner = nil;
    self.loadMoreView = nil;
    self.chatInput = nil;
    self.chatInputContainer = nil;
    self.chatBarView = nil;
    self.chatBar = nil;
    self.sendButton = nil;
    self.welcomeView = nil;
    self.welcomePrompt = nil;
    self.welcomeTitle = nil;
    self.closeWelcomePromptButton = nil;
    self.takePhotoButton = nil;

    self.translatePromptView = nil;
    self.translatePromptBubble = nil;
    self.sharePromptView = nil;
    self.sharePromptBubble = nil;
    
    self.selectedCell = nil;
    
    self.userProfileImage = nil;
    self.partnerProfileImage = nil;

    self.lastIndexPath = nil;
    self.selectedKey = nil;
    [spool release];
	[uploadPool release];
	[resendPool release];
    [downloadPool release];
    [retryPool release];
    [translationPool release];
    [translatedMessages release];
    [facebookSharePool release];
    [twitterSharePool release];
    [twitterQueue release];

    [super dealloc];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationIsPortrait(UIInterfaceOrientationPortrait);
}

- (bool)orientationChanged:(NSNotification *)notification
{
    UIInterfaceOrientation currentOrientation = [[UIDevice currentDevice] orientation];

    if(self.welcomeView.superview != nil)
    {
        return NO;
    }
    else if(UIDeviceOrientationIsLandscape(currentOrientation))
    {
        return YES;
    }
    else if(UIDeviceOrientationIsPortrait(currentOrientation))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self orientationChanged:nil];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, [UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO], 32)];

        [self.chatInput setMaxNumberOfLines:2];
        
        CGRect tableFrame = self._tableView.frame;
        [UIView beginAnimations:@"hideLocalTime" context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [self._tableView setFrame:CGRectMake(tableFrame.origin.x, 0, tableFrame.size.width, self.view.frame.size.height)];
        [UIView commitAnimations];

        // remove nav bar captions 
        [[self.navigationController navigationBar] performSelectorOnMainThread:@selector(removeCaptions) withObject:nil waitUntilDone:NO];
    }
    else
    {
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, 320, 54)];

        [self.chatInput setMaxNumberOfLines:3];
        
        CGRect tableFrame = self._tableView.frame;
        [UIView beginAnimations:@"showLocalTime" context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [self._tableView setFrame:CGRectMake(tableFrame.origin.x, 10, tableFrame.size.width, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES]-10)];
        [UIView commitAnimations];

        // restore nav bar captions
        if(chatDisabled == YES)
        {
            [[self.navigationController navigationBar] setCaption:NSLocalizedString(@"archiveCaption", nil)];
        }
        else
        {
            [navbarTimer fire];
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self._tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

#pragma mark - UI methods
- (void)setMissionsButton
{
    MissionViewControllerOld *missionControllerOld = [[MissionViewControllerOld alloc] init];
	[missionControllerOld setMatchNo:matchNo];
    [missionControllerOld setMatchData:matchData];
	bool hasNewMissions = [missionControllerOld hasNewMissions];
    [missionControllerOld checkNewMissions];
	[missionControllerOld release];

    UIImage *missionImage;
	if(hasNewMissions == NO && [[appDelegate.prefs valueForKey:@"hasNewMissions"] boolValue] == NO)
	{
		missionImage = [UIImage imageNamed:@"btn_missions.png"];
	}
	else
	{
		missionImage = [UIImage imageNamed:@"btn_missionsnew.png"];
	}
    
    // show archive if chat is disabled
    if(![[matchData valueForKey:@"status"] isEqualToString:@"Y"])
    {
        [self.navigationItem setRightBarButtonItem:nil];
    }
    else
    {
        CGRect missionFrame = CGRectMake(0, 0, missionImage.size.width, missionImage.size.height);
        CUIButton *missionButton = [[CUIButton alloc] initWithFrame:missionFrame];
        [missionButton setBackgroundImage:missionImage forState:UIControlStateNormal];
        [missionButton setShowsTouchWhenHighlighted:YES];
        [missionButton addTarget:self action:@selector(showMissionsAction) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *missionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:missionButton];
        [missionButton release];
        [self.navigationItem setRightBarButtonItem:missionBarButtonItem];
        [missionBarButtonItem release];
    }
}

- (void)setTimeForHeader
{
    UIViewController *currentView = [self.navigationController topViewController];
    if([currentView respondsToSelector:@selector(setTimeForHeader)] || [currentView respondsToSelector:@selector(setImage:)])
    {
        NSTimeZone *partnerTimezone = [NSTimeZone timeZoneForSecondsFromGMT:[[self.matchData valueForKey:@"timezoneOffset"] intValue]];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:partnerTimezone];
        [dateFormat setDefaultDate:[NSDate date]];
        NSDate *currentTime = [dateFormat defaultDate];
        [dateFormat setDateFormat:@"h:mm a"];
        NSString *currentTimeString = [dateFormat stringFromDate:currentTime];
        NSString *headerCaption = [NSString stringWithFormat:@"%@ %@", [self.matchData valueForKey:@"cityName"], currentTimeString];
        [dateFormat release];

        [[self.navigationController navigationBar] setCaption:headerCaption];
    }
}

- (void)scrollToBottomWithAnimation:(bool)animated
{
    if([self._tableView numberOfSections] > 0)
    {
        int lastSection = [self._tableView numberOfSections] - 1;

        if(self._tableView != nil && [self._tableView numberOfRowsInSection:lastSection] > 0)
        {
            int lastCell = [self._tableView numberOfRowsInSection:lastSection] - 1;
            NSIndexPath *lastCellIndex = [NSIndexPath indexPathForRow:lastCell inSection:lastSection];
            [self._tableView scrollToRowAtIndexPath:lastCellIndex atScrollPosition:UITableViewScrollPositionBottom animated:animated];
        }
    }
}

- (void)scrollToIndexPathWithAnimation:(NSIndexPath*)indexPath
{
    if(self._tableView != nil)
    {
        [self._tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)scrollToIndexPath:(NSIndexPath*)indexPath
{
    if(self._tableView != nil)
    {
        [self._tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

- (void)showWelcomeView
{
    if(showIntroPrompt == YES && [[self.matchData valueForKey:@"status"] isEqualToString:@"Y"])
    {
        [welcomePrompt.layer setMasksToBounds:YES];
        [welcomePrompt.layer setCornerRadius:8.0];

        [closeWelcomePromptButton.layer setMasksToBounds:YES];
        [closeWelcomePromptButton.layer setCornerRadius:5.0];
        [closeWelcomePromptButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
        [closeWelcomePromptButton.layer setBorderWidth: 1.0];
        [closeWelcomePromptButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
        [closeWelcomePromptButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];
        
        [takePhotoButton.layer setMasksToBounds:YES];
        [takePhotoButton.layer setCornerRadius:5.0];
        [takePhotoButton.layer setBorderColor:[[UIColor colorWithWhite:1.0 alpha:0.2] CGColor]];
        [takePhotoButton.layer setBorderWidth: 1.0];
        [takePhotoButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
        [takePhotoButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.2] forState:UIControlStateHighlighted];

        NSString *welcomeText = [welcomeTitle text];
        welcomeText = [welcomeText stringByReplacingOccurrencesOfString:@"{user}" withString:[appDelegate.prefs valueForKey:@"firstName"]];
        welcomeText = [welcomeText stringByReplacingOccurrencesOfString:@"{partner}" withString:[self.matchData valueForKey:@"firstName"]];
        [welcomeTitle setText:welcomeText];
        
        [welcomeView setFrame:self.view.bounds];
        [self.view addSubview:welcomeView];
        [welcomeView setAlpha:0];
        [UIView beginAnimations:@"showWelcome" context:nil];
        [UIView setAnimationDuration:1.0];
        [welcomeView setAlpha:1.0];
        [UIView commitAnimations];

        showIntroPrompt = NO;
    }
}

- (void)enableChatButton
{
    [self.sendButton setEnabled:YES];
}

- (void)disableChatButton
{
    [self.sendButton setEnabled:NO];
}

#pragma mark - helper methods
- (CGFloat)getTextWidth:(NSString *)text
{
    CGFloat result = 0;
	
	if (text)
	{
		CGSize textSize = {180.0f, 99999.0f};		// width and height of text area
		CGSize size = [text sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
		
		result = size.width;
	}
	
	return result;
}

- (CGFloat)getTextHeight:(NSString *)text
{
    CGFloat result = 0;
    
	if (text)
	{
		CGSize textSize = {180.0f, 99999.0f};		// width and height of text area
		CGSize size = [text sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
        
		result = size.height;
	}
    
	return result;
}

- (void)reloadIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *updatedCell = [self._tableView cellForRowAtIndexPath:indexPath];
    [self configureCell:updatedCell atIndexPath:indexPath];
    
    [self._tableView beginUpdates];
    [self._tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
    [self._tableView endUpdates];
}

- (void)translateText:(NSIndexPath*)indexPath
{
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    ChatData *chatData = (ChatData*)[threadContext objectWithID:[[self.fetchedResultsController objectAtIndexPath:indexPath] objectID]];
    NSString *key = [chatData valueForKey:@"key"];
    
    [self addToTranslationPool:key];
    [self performSelectorOnMainThread:@selector(reloadIndexPath:) withObject:indexPath waitUntilDone:NO];
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defs objectForKey:@"AppleLanguages"];
    NSString *preferredLang = [languages objectAtIndex:0];
    
    NSSet *translations = [chatData valueForKey:@"translationData"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"targetLanguage = %@", preferredLang];
    NSArray *fetchedTranslation = [[translations filteredSetUsingPredicate:predicate] allObjects];
    shouldScrollToBottom = NO;

    if([fetchedTranslation count] > 0)
    {
        TranslationData *translationResult = [fetchedTranslation objectAtIndex:0];
        NSString *translatedText = [translationResult valueForKey:@"translatedMessage"];
        [self addToTranslatedMessages:[NSDictionary dictionaryWithObjectsAndKeys:translatedText, @"message", key, @"key", nil]];
        [self.translationPool performSelectorOnMainThread:@selector(removeObject:) withObject:key waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(reloadIndexPath:) withObject:indexPath waitUntilDone:YES];
        
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"translateCacheHit"];
    }
    else
    {
        [appDelegate didStartNetworking];
        
        NSString *messageString = [[chatData valueForKey:@"message"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.googleapis.com/language/translate/v2?key=%@&target=%@&q=%@", googleTranslateKey, preferredLang, messageString]];
        
        ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:url];
        [request setAllowCompressedResponse:YES];
        [request setShouldWaitToInflateCompressedResponses:NO];
        [request setTimeOutSeconds:5];
        [request setNumberOfTimesToRetryOnTimeout:2];
        [request setShouldAttemptPersistentConnection:NO];
        [request startSynchronous];
        
        [appDelegate didStopNetworking];
        
        NSError *error = [request error];
        int statusCode = [request responseStatusCode];
        if (!error && statusCode == 200)
        {
            SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
            
            NSString *json_string = [request responseString];
            NSDictionary *apiResult = [jsonParser objectWithString:json_string error:nil];
            [jsonParser release];
            
            NSArray *translations = [[apiResult valueForKey:@"data"] valueForKey:@"translations"];
            
            if([translations count] > 0)
            {
                NSDictionary *translationResult = [translations objectAtIndex:0];
                NSString *translatedText = [[translationResult valueForKey:@"translatedText"] stringByDecodingHTMLEntities];
                [self addToTranslatedMessages:[NSDictionary dictionaryWithObjectsAndKeys:translatedText, @"message", key, @"key", nil]];
                
                [self.translationPool performSelectorOnMainThread:@selector(removeObject:) withObject:key waitUntilDone:NO];
                [self performSelectorOnMainThread:@selector(reloadIndexPath:) withObject:indexPath waitUntilDone:YES];

                NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"TranslationData" inManagedObjectContext:threadContext];

                [newManagedObject setValue:preferredLang forKey:@"targetLanguage"];
                [newManagedObject setValue:translatedText forKey:@"translatedMessage"];
                [newManagedObject setValue:chatData forKey:@"chatData"];
                [appDelegate saveContext:threadContext];

            }
        }
        [request release];
        
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"translateMessage"];
    }
}

- (void)getChatData:(int)offsetMessageNo
{
    NSMutableDictionary *downloadRequestData = [[NSMutableDictionary alloc] init];
    [downloadRequestData setValue:[NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]] forKey:@"memberNo"];
    [downloadRequestData setValue:[NSString stringWithFormat:@"%d", matchNo] forKey:@"matchNo"];
    [downloadRequestData setValue:[NSString stringWithFormat:@"%d", offsetMessageNo] forKey:@"offsetMessageNo"];
    
    NSDictionary *receivedData = [self.apiRequest sendServerRequest:@"chat" withTask:@"getAllMessages" withData:downloadRequestData];
    [downloadRequestData release];

    if(receivedData)
    {
        if([receivedData valueForKey:@"chatData"] != [NSNull null] && [receivedData valueForKey:@"chatData"] != nil)
        {
            NSArray *messages = [receivedData valueForKey:@"chatData"];
            
            if([[receivedData valueForKey:@"nextPageExists"] isEqualToString:@"Y"])
            {
                nextPageExists = YES;
            }
            
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *chatEntity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:appDelegate.mainMOC];
            [request setEntity:chatEntity];
            [request setIncludesPropertyValues:NO];
            
            NSError *error = nil;
            for(NSDictionary *chatData in messages)
            {
                NSAutoreleasePool *loopPool = [NSAutoreleasePool new];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo = %d AND messageNo = %d", matchNo, [[chatData valueForKey:@"messageNo"] intValue]]];
                [request setPredicate:predicate];
                
                NSUInteger count = [appDelegate.mainMOC countForFetchRequest:request error:&error];
                
                if(count == 0)
                {
                    // save in core data
                    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"ChatData" inManagedObjectContext:appDelegate.mainMOC];
                    
                    // set matchNo
                    [newManagedObject setValue:[NSNumber numberWithInt:matchNo] forKey:@"matchNo"];
                    
                    // set messageNo
                    [newManagedObject setValue:[NSNumber numberWithInt:[[chatData valueForKey:@"messageNo"] intValue]] forKey:@"messageNo"];
                    
                    // set key
                    [newManagedObject setValue:[chatData valueForKey:@"key"] forKey:@"key"];
                    
                    // set sender
                    NSInteger sender = [[chatData valueForKey:@"sender"] intValue];
                    [newManagedObject setValue:[NSNumber numberWithInt:sender] forKey:@"sender"];
                    
                    // set receiver
                    NSInteger receiver = [[chatData valueForKey:@"receiver"] intValue];
                    [newManagedObject setValue:[NSNumber numberWithInt:receiver] forKey:@"receiver"];
                    
                    // set is image
                    if([[chatData valueForKey:@"isImage"] intValue] == 1)
                    {
                        [newManagedObject setValue:[NSNumber numberWithBool:YES] forKey:@"isImage"];
                        
                        NSManagedObject *newManagedObject2 = [NSEntityDescription insertNewObjectForEntityForName:@"ImageData" inManagedObjectContext:appDelegate.mainMOC];
                        [newManagedObject2 setValue:[NSNumber numberWithInt:[[chatData valueForKey:@"messageNo"] intValue]] forKey:@"messageNo"];
                        [newManagedObject2 setValue:[chatData valueForKey:@"key"] forKey:@"key"];
                        
                        if([chatData valueForKey:@"fileNo"] != nil && [chatData valueForKey:@"fileNo"] != [NSNull null])
                        {
                            if([chatData valueForKey:@"missionNo"] != [NSNull null] && [chatData valueForKey:@"missionNo"] != nil)
                            {
                                NSNumber *missionNo = [NSNumber numberWithInt:[[chatData valueForKey:@"missionNo"] intValue]];
                                [newManagedObject2 setValue:missionNo forKey:@"missionNo"];
                                [newManagedObject2 setValue:[chatData valueForKey:@"description"] forKey:@"mission"];
                            }
                            
                            [newManagedObject2 setValue:[chatData valueForKey:@"caption"] forKey:@"caption"];
                            [newManagedObject2 setValue:[NSNumber numberWithFloat:[[chatData valueForKey:@"latitude"] floatValue]] forKey:@"latitude"];
                            [newManagedObject2 setValue:[NSNumber numberWithFloat:[[chatData valueForKey:@"longitude"] floatValue]] forKey:@"longitude"];
                            [newManagedObject2 setValue:[chatData valueForKey:@"cityName"] forKey:@"cityName"];
                            [newManagedObject2 setValue:[chatData valueForKey:@"provinceName"] forKey:@"provinceName"];
                            [newManagedObject2 setValue:[chatData valueForKey:@"provinceCode"] forKey:@"provinceCode"];
                            [newManagedObject2 setValue:[chatData valueForKey:@"countryName"] forKey:@"countryName"];
                            [newManagedObject2 setValue:[chatData valueForKey:@"countryCode"] forKey:@"countryCode"];
                            [newManagedObject2 setValue:[chatData valueForKey:@"locationName"] forKey:@"locationName"];
                            [newManagedObject2 setValue:[chatData valueForKey:@"locationId"] forKey:@"locationId"];
                            
                            NSString *captionText = [chatData valueForKey:@"caption"];
                            CGSize captionSize = {180.0f, 99999.0f};		// width and height of text area
                            CGSize size = [captionText sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:captionSize lineBreakMode:UILineBreakModeWordWrap];
                            
                            [newManagedObject2 setValue:[NSNumber numberWithFloat:size.height] forKey:@"captionHeight"];
                        }
                        
                        // set chat data relationship
                        [newManagedObject2 setValue:newManagedObject forKey:@"chatData"];
                    }
                    else
                    {
                        // set message
                        if([chatData valueForKey:@"message"] != [NSNull null] && [chatData valueForKey:@"message"] != nil)
                        {
                            [newManagedObject setValue:[chatData valueForKey:@"message"] forKey:@"message"];
                            
                            // set with and height for text
                            NSString *messageText = [chatData valueForKey:@"message"];
                            CGSize textSize = {180.0f, 99999.0f};		// width and height of text area
                            CGSize size = [messageText sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
                            [newManagedObject setValue:[NSNumber numberWithFloat:size.width] forKey:@"textWidth"];
                            [newManagedObject setValue:[NSNumber numberWithFloat:size.height] forKey:@"textHeight"];
                        }
                    }
                    
                    // set status
                    [newManagedObject setValue:[NSNumber numberWithInt:0] forKey:@"status"];
                    
                    // set date
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSDate *sendDate = [formatter dateFromString:[chatData valueForKey:@"sendDate"]];
                    [newManagedObject setValue:sendDate forKey:@"datetime"];
                    [formatter release];
                    
                    // set detected language
                    if([chatData valueForKey:@"detectedLanguage"] != [NSNull null] && [chatData valueForKey:@"detectedLanguage"] != nil)
                    {
                        [newManagedObject setValue:[chatData valueForKey:@"detectedLanguage"] forKey:@"detectedLanguage"];
                    }
                    
                    // set match data relationship
                    [newManagedObject setValue:[appDelegate.mainMOC objectWithID:[matchData objectID]] forKey:@"matchData"];
                }
                [loopPool drain];
            }
            [appDelegate saveContext:appDelegate.mainMOC];
            [request release];
        }
    }
}

- (void)updateChatTable
{
    if(self.fetchedResultsController != nil)
    {
        int currentNumberOfRows = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
        if(maxListItems < currentNumberOfRows)
        {
            maxListItems += 25;
            nextPageExists = YES;
            [self.loadMoreView setHidden:NO];
        }
        
        if(currentNumberOfRows > 0)
        {
            [shareSomething setHidden:YES];
        }
    }
    
    if(receivedNewMessage == YES)
    {
        [self scrollToBottomWithAnimation:YES];
        receivedNewMessage = NO;
    }
}

- (void)getMoreMessages
{
    int currentNumberOfRows = [self._tableView numberOfRowsInSection:0];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:appDelegate.mainMOC];
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesPropertyValues:NO];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = %d and (key != nil OR messageNo != 0)", matchNo];
    [fetchRequest setPredicate:predicate];

    NSError *error;
    NSUInteger count = [appDelegate.mainMOC countForFetchRequest:fetchRequest error:&error];

    if(count <= maxListItems && [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects] > 0)
    {
        ChatData *lastMessage = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        int lastMessageNo = [[lastMessage valueForKey:@"messageNo"] intValue];

        [self getChatData:lastMessageNo];
        count = [appDelegate.mainMOC countForFetchRequest:fetchRequest error:&error];
    }
    [fetchRequest release];

    if(count > maxListItems)
    {
        // delete the cache first
        [NSFetchedResultsController deleteCacheWithName:nil];

        maxListItems = maxListItems + 25;
        int offset = count - maxListItems;
        
        if(offset < count)
        {
            [self.fetchedResultsController.fetchRequest setFetchOffset:offset];
            nextPageExists = YES;
        }
        else
        {
            [self.fetchedResultsController.fetchRequest setFetchOffset:0];
            nextPageExists = NO;
        }
        
        NSError *error;
        if(![self.fetchedResultsController performFetch:&error])
        {
            NSLog(@"get next chat page error: %@", error);
        }
        else
        {
            [self._tableView reloadData];
            
            int updatedNumberOfRows = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
            int targetRow = updatedNumberOfRows - currentNumberOfRows;
            
            NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:targetRow inSection:0];
            if(self._tableView != nil) [self._tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            
            if(targetRow - 1 > 0)
            {
                int newRowOffset = targetRow - 1;
                if(newRowOffset > 0 && newRowOffset < updatedNumberOfRows)
                {
                    NSIndexPath *scrollIndexPath2 = [NSIndexPath indexPathForRow:newRowOffset inSection:0];
                    CGRect cellRect = [self._tableView rectForRowAtIndexPath:scrollIndexPath2];
                    CGRect newRect = CGRectMake(cellRect.origin.x, cellRect.origin.y + 25, cellRect.size.width, cellRect.size.height);
                    if(self._tableView != nil) [self._tableView scrollRectToVisible:newRect animated:YES];
                }
            }
        }
    }
    else
    {
        nextPageExists = NO;
    }
    
    if(nextPageExists == YES)
    {
        [self.loadMoreLabel setHidden:NO];
        [self.loadingLabel setHidden:YES];
        [self.loadingSpinner stopAnimating];
    }
    else
    {
        [self.loadMoreView setHidden:YES];
        nextPageExists = NO;
    }
    
    [self._tableView setContentInset:UIEdgeInsetsZero];
}

#pragma mark - gesture handlers
- (void)handleLongPress:(UILongPressGestureRecognizer*)recognizer
{
    CUIButton *pressedButton = (CUIButton*)recognizer.view;

    id currentNode = pressedButton;
    while(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        currentNode = [currentNode superview];
    }
    
    if(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        return;
    }

    self.selectedCell = currentNode;

    UIView *customCell = [self.selectedCell.contentView viewWithTag:0];
    UITextView *messageTextView = (UITextView*)[customCell viewWithTag:3];

    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            [messageTextView setTextColor:UIColorFromRGB(0x777777)];
            tapHoldTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(showMessageContextMenu:) userInfo:nil repeats:NO];
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
            [messageTextView setTextColor:[UIColor colorWithWhite:0.0 alpha:1.0]];
            [tapHoldTimer invalidate];
            tapHoldTimer = nil;
            break;
        default:
            break;
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer*)recognizer
{
    CUIButton *pressedButton = (CUIButton*)recognizer.view;
    
    id currentNode = pressedButton;
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

    switch (recognizer.state)
    {
        case UIGestureRecognizerStateRecognized:
            if(translationPromptIsVisable == NO && [appDelegate.prefs boolForKey:@"didShowContextMenu"] == NO)
            {
                ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
                translationPromptIsVisable = YES;
                
                [self.translatePromptBubble.layer setMasksToBounds:YES];
                [self.translatePromptBubble.layer setCornerRadius:8.0];

                CGRect cellRect = [_tableView rectForRowAtIndexPath:indexPath];
                
                float y = 0;
                if(cellRect.origin.y > self.translatePromptView.frame.size.height)
                {
                    y = (cellRect.origin.y - self.translatePromptView.frame.size.height) + 12;
                    [[self.translatePromptView viewWithTag:1] setHidden:YES];
                    [[self.translatePromptView viewWithTag:2] setHidden:NO];
                }
                else
                {
                    float cellHeight = [[chatData valueForKey:@"textHeight"] floatValue] + 43;
                    y = (cellRect.origin.y + cellHeight) - 12;
                    [[self.translatePromptView viewWithTag:1] setHidden:NO];
                    [[self.translatePromptView viewWithTag:2] setHidden:YES];
                }
                
                [self.translatePromptView setFrame:CGRectMake(20, y, self.translatePromptView.frame.size.width, self.translatePromptView.frame.size.height)];
                
                [_tableView addSubview:self.translatePromptView];
                [self.translatePromptView setAlpha:0.0];
                
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                [UIView setAnimationDuration:0.2f];
                [self.translatePromptView setAlpha:1.0];
                [UIView commitAnimations];

                self.selectedCell = nil;
            }
            
            break;
        default:
            break;
    } 
}

- (void)handleDoubleTap:(UITapGestureRecognizer*)recognizer
{
    CUIButton *pressedButton = (CUIButton*)recognizer.view;
    
    id currentNode = pressedButton;
    while(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        currentNode = [currentNode superview];
    }
    
    if(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        return;
    }
    
    self.selectedCell = currentNode;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateRecognized:
            [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(showMessageContextMenu:) userInfo:nil repeats:NO];
            break;
        default:
            break;
    }
}

#pragma mark - photo delivery helpers
- (void)downloadThumbnail:(NSNumber*)messageNo withProgressView:(UIProgressView*)progressView
{
	NSMutableDictionary *downloadRequestData = [[NSMutableDictionary alloc] init];
	[downloadRequestData setValue:messageNo forKey:@"messageNo"];
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
    {
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 370] forKey:@"width"];
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 280] forKey:@"height"];
    }
    else
    {
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 185] forKey:@"width"];
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 140] forKey:@"height"];
    }

	[self.apiRequest getAsyncDataFromServer:@"chat" withTask:@"downloadPhoto" withData:downloadRequestData progressDelegate:progressView];
    shouldScrollToBottom = NO;
	[downloadRequestData release];
}

// prepare to send photos
- (void)sendPhoto:(ImageData*)imageDataObject withImageData:(NSData*)imageData withProgressView:(UIProgressView*)progressView
{
    NSString *key = [imageDataObject valueForKey:@"key"];
    float latitude = [[imageDataObject valueForKey:@"latitude"] floatValue];
    float longitude = [[imageDataObject valueForKey:@"longitude"] floatValue];
    
	// prepare data
	int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
	NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
	[requestData setValue:key forKey:@"key"];
	[requestData setValue:[NSString stringWithFormat:@"%d", matchNo] forKey:@"matchNo"];
	[requestData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
	[requestData setValue:[NSString stringWithFormat:@"%d", [[self.matchData valueForKey:@"partnerNo"] intValue]] forKey:@"partnerNo"];
    
    NSString *missionNoString = [NSString stringWithFormat:@"%d", [[imageDataObject valueForKey:@"missionNo"] intValue]];
    [requestData setValue:missionNoString forKey:@"missionNo"];
    [requestData setValue:[imageDataObject valueForKey:@"caption"] forKey:@"caption"];
    [requestData setValue:[NSString stringWithFormat:@"%f", latitude] forKey:@"latitude"];
    [requestData setValue:[NSString stringWithFormat:@"%f", longitude] forKey:@"longitude"];
    [requestData setValue:[imageDataObject valueForKey:@"cityName"] forKey:@"cityName"];
    [requestData setValue:[imageDataObject valueForKey:@"provinceName"] forKey:@"provinceName"];
    [requestData setValue:[imageDataObject valueForKey:@"provinceCode"] forKey:@"provinceCode"];
    [requestData setValue:[imageDataObject valueForKey:@"countryName"] forKey:@"countryName"];
    [requestData setValue:[imageDataObject valueForKey:@"countryCode"] forKey:@"countryCode"];
    [requestData setValue:[imageDataObject valueForKey:@"locationName"] forKey:@"locationName"];
    [requestData setValue:[imageDataObject valueForKey:@"locationId"] forKey:@"locationId"];
    
	[requestData setValue:[appDelegate.prefs valueForKey:@"firstName"] forKey:@"firstName"];
	[requestData setObject:imageData forKey:@"imageData"];
    if(latitude != 0 && longitude != 0)
    {
        [requestData setValue:[NSString stringWithFormat:@"%f", latitude] forKey:@"latitude"];
        [requestData setValue:[NSString stringWithFormat:@"%f", longitude] forKey:@"longitude"];
    }
    
    if(progressView != nil)
    {
        [requestData setObject:progressView forKey:@"progressView"];
    }
    
	// check if the photo is being resent
	if([resendPool containsObject:key])
	{
		[requestData setValue:@"Y" forKey:@"resend"];
		[resendPool removeObjectAtIndex:[resendPool indexOfObject:key]];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"resendPhoto"];
	}
    else
    {
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"sendPhoto"];
    }
    
	// send to server
	[self sendPhotoToServer:requestData];
    [requestData release];
}

// send photos to the server
- (void)sendPhotoToServer:(NSMutableDictionary*)requestData
{
	// get image	
	NSData *imageData = [requestData objectForKey:@"imageData"];
    
	// get progress view
	id progressView = [requestData objectForKey:@"progressView"];
    
	if(imageData)
	{
		NSMutableDictionary *uploadRequestData = [[NSMutableDictionary alloc] initWithDictionary:requestData];
		[uploadRequestData removeObjectForKey:@"imageData"];
		[uploadRequestData removeObjectForKey:@"progressView"];
		[self.apiRequest uploadImageFile:@"chat" withTask:@"sendPhoto" withImageData:imageData withData:uploadRequestData progressDelegate:progressView];
		[uploadRequestData release];
	}
}

// set thumbnail data for the message on chat screen
- (void)setThumbnailData:(NSDictionary*)thumbnailData
{
    UIImage *image = [thumbnailData valueForKey:@"imageData"];
    NSString *key = [thumbnailData valueForKey:@"key"];
    NSString *url = [thumbnailData valueForKey:@"url"];
    int retryCount = [[thumbnailData valueForKey:@"retryCount"] intValue];
    NSString *thumbnailFile = [thumbnailData valueForKey:@"thumbnailFile"];
    
    if(thumbnailFile == nil)
    {
        thumbnailFile = [UtilityClasses saveImageData:UIImageJPEGRepresentation(image, 1.0) named:@"thumbnail" withKey:key overwrite:YES];
    }
    
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    NSManagedObjectID *objectID = [downloadPool valueForKey:key];
    ChatData *chatObject = (ChatData*)[threadContext objectWithID:objectID];
    [threadContext refreshObject:chatObject mergeChanges:YES];

    if(chatObject.matchData == nil)
    {
        if(retryCount < 3)
        {
            retryCount++;
            NSMutableDictionary *retryThumbnailData = [NSMutableDictionary dictionaryWithDictionary:thumbnailData];
            [retryThumbnailData setValue:thumbnailFile forKey:@"thumbnailFile"];
            [retryThumbnailData setValue:[NSNumber numberWithInt:retryCount] forKey:@"retryCount"];
            [self setThumbnailData:retryThumbnailData];
            return;
        }
        else
        {
            // remove from download pool
            [downloadPool performSelectorOnMainThread:@selector(removeObjectForKey:) withObject:key waitUntilDone:YES];
            return;
        }
    }

	// set status and thumbnail image
    [chatObject setValue:[NSNumber numberWithInt:0] forKey:@"status"];

    // set thumbnail file
    [chatObject setValue:thumbnailFile forKey:@"thumbnailFile"];

    // set url for image
    ImageData *imageData = [chatObject valueForKey:@"imageData"];
    [imageData setValue:url forKey:@"url"];

    // save
    [appDelegate saveContext:threadContext];
    
	// remove from download pool
	[downloadPool performSelectorOnMainThread:@selector(removeObjectForKey:) withObject:key waitUntilDone:YES];
}

#pragma mark - navigation methods
- (void)showMissionsAction
{
    [self showMissions:YES selectMission:nil];
}

- (void)showMissions:(bool)animated selectMission:(NSNumber*)missionNo
{
	if(appDelegate.networkStatus == NO)
	{
		return;
	}
    
	// init mission controller
	MissionViewControllerOld *missionControllerOld = [[MissionViewControllerOld alloc] initWithNibName:@"MissionViewControllerOld" bundle:nil];
	[missionControllerOld setMatchNo:matchNo];
    [missionControllerOld setMatchData:matchData];
    [missionControllerOld setSelectedMissionNo:missionNo];
	[missionControllerOld setViewTitle:[self.matchData valueForKey:@"firstName"]];
	[missionControllerOld setDelegate:self];
    
    if(animated == YES)
    {
        CATransition *modalAnimation = [CATransition animation];
        [modalAnimation setDuration:0.3];
        [modalAnimation setType:kCATransitionMoveIn];
        
        if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft)
        {
            [modalAnimation setSubtype:kCATransitionFromRight];
        }
        else if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)
        {
            [modalAnimation setSubtype:kCATransitionFromLeft];
        }
        else
        {
            [modalAnimation setSubtype:kCATransitionFromTop];
        }
        
        [modalAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [modalAnimation setDelegate:self];
        [self.navigationController.view.layer addAnimation:modalAnimation forKey:nil];
    }
	[self.navigationController pushViewController:missionControllerOld animated:NO];
    shouldScrollToBottom = NO;
    
	[missionControllerOld release];
}

- (void)goBack
{
	CGRect tableFrame = self._tableView.frame;
	[UIView beginAnimations:@"hideLocalTime" context:nil];
	[UIView setAnimationDuration:0.25];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[self._tableView setFrame:CGRectMake(tableFrame.origin.x, 0, tableFrame.size.width, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES])];
	[UIView commitAnimations];
    
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)loadProfile
{
    [self.chatInput resignFirstResponder];

    MatchIntroViewController *matchIntroController = [[MatchIntroViewController alloc] initWithNibName:@"MatchIntroViewController" bundle:nil];
    [matchIntroController setIsModalView:YES];
    [matchIntroController setMatchData:matchData];
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:matchIntroController];
    [self presentModalViewController:newNavController animated:YES];
    [newNavController release];
    [matchIntroController release];
    
    shouldScrollToBottom = NO;
}

- (void)didTouchThumbnailForObject:(NSManagedObjectID*)objectID showMap:(bool)showMap;
{
    ChatData *chatData = (ChatData*)[appDelegate.mainMOC objectWithID:objectID];
    NSString *key = [chatData valueForKey:@"key"];

	if([[chatData valueForKey:@"status"] intValue] == 0)
	{
		ViewPhotoController	*viewPhotoController = [[ViewPhotoController alloc] initWithNibName:@"ViewPhotoController" bundle:nil];
        [viewPhotoController setDelegate:self];
        [viewPhotoController setKey:key];
        [viewPhotoController setMatchData:matchData];
        [viewPhotoController setChatData:chatData];
        [viewPhotoController setShowMap:showMap];
		[self.navigationController pushViewController:viewPhotoController animated:YES];
		[viewPhotoController release];
        shouldScrollToBottom = NO;
	}
}

- (void)didTouchThumbnail:(id)sender
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

    NSIndexPath *indexPath = [self._tableView indexPathForCell:currentNode];
    ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
	[self didTouchThumbnailForObject:[chatData objectID] showMap:NO];
}

- (void)didTouchLocation:(id)sender
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
    
    NSIndexPath *indexPath = [self._tableView indexPathForCell:currentNode];
    ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
	[self didTouchThumbnailForObject:[chatData objectID] showMap:YES];
}

- (void)didTouchMission:(id)sender
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
    
    NSIndexPath *indexPath = [self._tableView indexPathForCell:currentNode];
    ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSNumber *missionNo = [chatData valueForKey:@"missionNo"];

	[self showMissions:YES selectMission:missionNo];
}

- (void)showShareViewController:(NSDictionary*)controllerData
{
    UIImage *image = [controllerData valueForKey:@"image"];
    UIImage *thumbnail = [controllerData valueForKey:@"thumbnail"];
    bool shouldSaveToCameraRoll = [[controllerData valueForKey:@"shouldSaveToCameraRoll"] boolValue];
    UIImagePickerControllerSourceType sourceType = [[controllerData valueForKey:@"sourceType"] intValue];
    
    [self.shareController setSelectedImage:image];
    [self.shareController setThumbnail:thumbnail];
    [self.shareController setShouldResetNavController:NO];
    [self.shareController setSourceType:sourceType];
    [self.shareController setShouldSaveToCameraRoll:shouldSaveToCameraRoll];
    
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:self.shareController];
    [self presentModalViewController:newNavController animated:NO];
    [newNavController release];
    
    [appDelegate performSelector:@selector(hideLoading) withObject:nil afterDelay:0.0];
}

- (void)pushShareControllerWithData:(NSDictionary*)data
{
    UIImagePickerController *picker = [data valueForKey:@"picker"];
    UIImage *image = [data valueForKey:@"image"];
    bool shouldSaveToCameraRoll = [[data valueForKey:@"shouldSaveToCameraRoll"] boolValue];
    UIImagePickerControllerSourceType sourceType = [[data valueForKey:@"sourceType"] intValue];
    NSNumber *missionNo = [data valueForKey:@"missionNo"];
    NSString *mission = [data valueForKey:@"mission"];
    
    UIImage *thumbnail = nil;
    if([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
    {
        thumbnail = [image resizedImageByScalingProportionally:CGSizeMake(160.0, 160.0)];
        thumbnail = [thumbnail resizedImage:CGSizeMake(160, 160) interpolationQuality:kCGInterpolationLow];
    }
    else
    {
        thumbnail = [image resizedImageByScalingProportionally:CGSizeMake(80.0, 80.0)];
        thumbnail = [thumbnail resizedImage:CGSizeMake(80, 80) interpolationQuality:kCGInterpolationLow];
    }

    self.shareController = nil;
    self.shareController = [[[SharePhotoController alloc] initWithNibName:@"SharePhotoController" bundle:nil] autorelease];
    [self.shareController setDelegate:self];
    [self.shareController setMatchData:matchData];
    if(missionNo != nil) [self.shareController setMissionNo:missionNo];
    if(mission != nil) [self.shareController setMission:mission];
    [self.shareController setSelectedImage:image];
    [self.shareController setThumbnail:thumbnail];
    [self.shareController setShouldResetNavController:YES];
    [self.shareController setShouldSaveToCameraRoll:shouldSaveToCameraRoll];
    [self.shareController setSourceType:sourceType];
    [picker performSelector:@selector(pushViewController:animated:) withObject:self.shareController withObject:[NSNumber numberWithBool:YES]];
    shouldScrollToBottom = NO;
}

#pragma mark - IBActions
- (IBAction)sendMessage
{
    if(![chatInput.text isEqualToString:@""])
    {
        [self disableChatButton];
        
        NSString *message = self.chatInput.text;
        QueueMessageOperation *queueMessageOperation = [[QueueMessageOperation alloc] initWithMatchData:matchData andMessage:message resendWithObject:nil];
        [queueMessageOperation setThreadPriority:1.0];
        [self.operationQueue addOperation:queueMessageOperation];
        [queueMessageOperation release];
        
        [self.chatInput setText:@""];

        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"sendTextMessage"];
        [self performSelector:@selector(enableChatButton) withObject:nil afterDelay:1.0];
    }
}

- (IBAction)hideWelcomeView
{
    [UIView beginAnimations:@"hideWelcomeView" context:nil];
	[UIView setAnimationDuration:0.5];
	[welcomeView setAlpha:0];
    [UIView commitAnimations];
    [welcomeView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5];
}

- (IBAction)attach
{
    [self.chatInput resignFirstResponder];

	UIActionSheet *sheet;
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		sheet = [[UIActionSheet alloc]
				 initWithTitle:nil
				 delegate:self
				 cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
				 destructiveButtonTitle:nil
				 otherButtonTitles:NSLocalizedString(@"takePhotoButton", nil), NSLocalizedString(@"choosePhotoButton", nil), nil];
	}
	else
	{
		sheet = [[UIActionSheet alloc]
				 initWithTitle:nil
				 delegate:self
				 cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
				 destructiveButtonTitle:nil
				 otherButtonTitles:NSLocalizedString(@"choosePhotoButton", nil), nil];
	}
	sheet.tag = 0;
	[sheet showInView:self.view];
	[sheet release];
}

- (IBAction)takeWelcomePhoto
{
    [self hideWelcomeView];
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setDelegate:self];
        [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [self presentModalViewController:picker animated:YES];
        [picker release];
    }
    else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setDelegate:self];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [self presentModalViewController:picker animated:YES];
        [picker release];
    }
}

- (void)showOptions:(UIButton*)sender
{    
	UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:nil
                            delegate:self
                            cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                            destructiveButtonTitle:NSLocalizedString(@"deleteButton", nil)
                            otherButtonTitles:NSLocalizedString(@"resendButton", nil), nil];
	[sheet setTag:1];
    
	id currentNode = sender;
    while(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        currentNode = [currentNode superview];
    }
    
    if(![currentNode isKindOfClass:[UITableViewCell class]])
    {
        [sheet release];
        return;
    }
    
    self.selectedCell = currentNode;
    
	[chatInput resignFirstResponder];
	[sheet showInView:self.view];
	[sheet release];
}

- (IBAction)dismissTranslationPrompt
{
    if(translationPromptIsVisable == YES)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2f];
        [self.translatePromptView setAlpha:0.0];
        [UIView commitAnimations];

        [self.translatePromptView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
        
        translationPromptIsVisable = NO;
    }
}

- (IBAction)dismissSharePrompt
{
    if(sharePromptIsVisable == YES)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:0.2f];
        [self.sharePromptView setAlpha:0.0];
        [UIView commitAnimations];
        
        [self.sharePromptView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];
        
        sharePromptIsVisable = NO;
    }
}

- (void)showMessageContextMenu:(NSTimer*)timer
{
    [self dismissTranslationPrompt];
    [chatInput resignFirstResponder];

    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
    ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *key = [chatData valueForKey:@"key"];
    int senderNo = [[chatData valueForKey:@"sender"] intValue];
    
    if([self.translatedMessages valueForKey:key])
    {
        UIActionSheet *sheet = [[UIActionSheet alloc]
                                initWithTitle:nil
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                                destructiveButtonTitle:nil
                                otherButtonTitles:NSLocalizedString(@"copyToClipboardButton", nil), NSLocalizedString(@"showOriginalMessageButton", nil), nil];
        [sheet setTag:20];
        [sheet showInView:self.view];
        [sheet release];
    }
    else if(senderNo != [appDelegate.prefs integerForKey:@"memberNo"])
    {
        UIActionSheet *sheet = [[UIActionSheet alloc]
                                initWithTitle:nil
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                                destructiveButtonTitle:nil
                                otherButtonTitles:NSLocalizedString(@"copyToClipboardButton", nil), NSLocalizedString(@"translateMessageButton", nil), nil];
        [sheet setTag:10];
        [sheet showInView:self.view];
        [sheet release];
    }
    else
    {
        UIActionSheet *sheet = [[UIActionSheet alloc]
                                initWithTitle:nil
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                                destructiveButtonTitle:nil
                                otherButtonTitles:NSLocalizedString(@"copyToClipboardButton", nil), nil];
        [sheet setTag:30];
        [sheet showInView:self.view];
        [sheet release];
    }
    
    [appDelegate.prefs setBool:YES forKey:@"didShowContextMenu"];
    [appDelegate.prefs synchronize];
    [_tableView reloadData];
}

#pragma mark - properties
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController == nil)
    {
        // Create and configure a fetch request with the Book entity.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:appDelegate.mainMOC];
        [fetchRequest setEntity:entity];
        [fetchRequest setReturnsObjectsAsFaults:YES];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = %d and (key != nil OR messageNo != 0)", matchNo];
        [fetchRequest setPredicate:predicate];
        
        NSError *error;
        NSUInteger count = [appDelegate.mainMOC countForFetchRequest:fetchRequest error:&error];

        nextPageExists = YES;
        if(count > maxListItems)
        {
            int offset = count - maxListItems;
            [fetchRequest setFetchOffset:offset];
            [self.loadMoreView setHidden:NO];
        }
        else if(count == 0)
        {
            [self getChatData:0];
            if(nextPageExists == YES)
            {
                [self.loadMoreView setHidden:NO];
            }
            else
            {
                [self.loadMoreView setHidden:YES];
            }
        }

        // Create the sort descriptors array.
        NSSortDescriptor *statusDescripter = [[NSSortDescriptor alloc] initWithKey:@"status" ascending:YES];
        NSSortDescriptor *messageDescripter = [[NSSortDescriptor alloc] initWithKey:@"messageNo" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:statusDescripter, messageDescripter, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];

        // Create and initialize the fetch results controller.
        [NSFetchedResultsController deleteCacheWithName:nil];
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:appDelegate.mainMOC sectionNameKeyPath:nil cacheName:[NSString stringWithFormat:@"%d_chatData.cache", matchNo]];

        _fetchedResultsController = aFetchedResultsController;
        _fetchedResultsController.delegate = self;
        
        // Memory management.
        [fetchRequest release];
        [statusDescripter release];
        [messageDescripter release];
        [sortDescriptors release];
    }

	return _fetchedResultsController;
}

- (NSMutableDictionary*)photoCache
{
    if(_photoCache == nil)
    {
        _photoCache = [[NSMutableDictionary alloc] init];
    }
    return _photoCache;
}

- (NSMutableDictionary*)photoDataCache
{
    if(_photoDataCache == nil)
    {
        _photoDataCache = [NSMutableDictionary dictionaryWithCapacity:MAX_CACHED_IMAGES];
        [_photoDataCache retain];
    }
    return _photoDataCache;
}

- (UIImage*)userProfileImage
{
    if(_userProfileImage == nil)
    {
        NSString *imagesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images"];
        NSString *imagePath = [NSBundle pathForResource:@"profileImage" ofType:@"png" inDirectory:imagesDirectory];

        if(imagePath)
        {
            UIImage *profileImage = [UIImage imageFromFile:imagePath];
            UIImage *resizedImage = nil;
            if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
            {
                resizedImage = [profileImage resizedImageByScalingProportionally:CGSizeMake(90.0, 90.0)];
            }
            else
            {
                resizedImage = [profileImage resizedImageByScalingProportionally:CGSizeMake(45.0, 45.0)];
            }
            
            _userProfileImage = [resizedImage retain];
        }
    }
    return _userProfileImage;
}

- (UIImage*)partnerProfileImage
{
    if(_partnerProfileImage == nil)
    {
        NSString *profileImagePath = [NSHomeDirectory() stringByAppendingPathComponent:[matchData valueForKey:@"profileImage"]];            
        UIImage *profileImageFull = [UIImage imageFromFile:profileImagePath];

        UIImage *resizedImage = nil;
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
        {
            resizedImage = [profileImageFull resizedImageByScalingProportionally:CGSizeMake(90.0, 90.0)];
        }
        else
        {
            resizedImage = [profileImageFull resizedImageByScalingProportionally:CGSizeMake(45.0, 45.0)];
        }
        _partnerProfileImage = [resizedImage retain];
    }
    
    return _partnerProfileImage;
}

- (SA_OAuthTwitterEngine*)twitter
{
    if(_twitter == nil)
    {
        _twitter = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
        _twitter.consumerKey = twitterKey;
        _twitter.consumerSecret = twitterSecret;
    }
    return _twitter;
}

#pragma mark - queue pools
- (void)addToTextPool:(NSString*)key
{
    if(self.spool == nil) self.spool = [[[NSMutableArray alloc] init] autorelease];
	[spool addObject:key];
}

- (void)addObjectIDToUploadPool:(NSManagedObjectID*)objectID forKey:(NSString*)key
{
    if(self.uploadPool == nil) self.uploadPool = [[[NSMutableDictionary alloc] init] autorelease];
	[uploadPool setValue:objectID forKey:key];
}

- (void)addToResendPool:(NSString*)key
{
    if(self.resendPool == nil) self.resendPool = [[[NSMutableArray alloc] init] autorelease];
	[resendPool addObject:key];
}

- (void)addObjectIDToDownloadPool:(NSManagedObjectID*)objectID forKey:(NSString*)key
{
    if(self.downloadPool == nil) self.downloadPool = [[[NSMutableDictionary alloc] init] autorelease];
	[downloadPool setValue:objectID forKey:key];
}

- (void)addToRetryPool:(NSNumber*)retryCount forKey:(NSString*)key
{
    if(self.retryPool == nil) self.retryPool = [[[NSMutableDictionary alloc] init] autorelease];
	[retryPool setValue:retryCount forKey:key];
}

- (void)addToTranslationPool:(NSString*)key
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:key waitUntilDone:NO];
        return;
    }

    if(self.translationPool == nil) self.translationPool = [[[NSMutableArray alloc] init] autorelease];
	[translationPool addObject:key];
}

- (void)addToTranslatedMessages:(NSDictionary*)translatedMessage
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:translatedMessage waitUntilDone:NO];
        return;
    }

    if(self.translatedMessages == nil) self.translatedMessages = [[[NSMutableDictionary alloc] init] autorelease];
	[translatedMessages setValue:[translatedMessage valueForKey:@"message"] forKey:[translatedMessage valueForKey:@"key"]];
}

- (void)addToTwitterQueue:(NSString*)requestId forKey:(NSString*)key
{
    if(self.twitterQueue == nil) self.twitterQueue = [[[NSMutableDictionary alloc] init] autorelease];
    [twitterQueue setValue:key forKey:requestId];
}

- (void)addToFacebookSharePool:(NSString*)key withData:(NSMutableDictionary*)shareData
{
    if(self.facebookSharePool == nil) self.facebookSharePool = [[[NSMutableDictionary alloc] init] autorelease];
    [facebookSharePool setObject:shareData forKey:key];
}

- (void)addToTwitterSharePool:(NSString*)key withData:(NSMutableDictionary*)shareData
{
    if(self.twitterSharePool == nil) self.twitterSharePool = [[[NSMutableDictionary alloc] init] autorelease];
    [twitterSharePool setObject:shareData forKey:key];
}

#pragma mark - twitter
- (void)newTweetForObjectID:(NSManagedObjectID*)objectID;
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"touchTweetFromChatView"];

    ChatData *chatData = (ChatData*)[appDelegate.mainMOC objectWithID:objectID];
    ImageData *imageData = [chatData valueForKey:@"imageData"];
    
    // show twitter auth view if user is not signed in
    if([self.twitter isAuthorized] == NO)
    {
        UIViewController *controller = [SA_OAuthTwitterController controllerToEnterCredentialsWithTwitterEngine:self.twitter delegate:self];
        [self presentModalViewController:controller animated:YES];
        shouldScrollToBottom = NO;
    }
    else
    {
        shouldLoadTweet = NO;
        self.selectedCell = nil;
        
        if([[imageData valueForKey:@"url"] isEqualToString:@""] || [imageData valueForKey:@"url"] == nil)
        {
            [self didTouchThumbnailForObject:[chatData objectID] showMap:NO];
        }
        else
        {
            NSString *thumbnailPath = [NSHomeDirectory() stringByAppendingPathComponent:[chatData valueForKey:@"thumbnailFile"]];
            UIImage *theThumbnail = [UIImage imageFromFile:thumbnailPath];
            UIImage *thumbnail = [theThumbnail resizedImageByScalingProportionally:CGSizeMake(30.0, 30.0)];
            
            TweetViewController *tweetController = [[TweetViewController alloc] initWithNibName:@"TweetViewController" bundle:nil];
            [tweetController setLinkUrl:[imageData valueForKey:@"url"]];
            [tweetController setThumbnailImage:thumbnail];
            [tweetController setImageKey:[imageData valueForKey:@"key"]];
            [tweetController setIsOwner:NO];
            UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:tweetController];
            [[newNavController navigationBar] setBackgroundColor:[UIColor clearColor]];
            [self presentModalViewController:newNavController animated:YES];
            [tweetController release];
            [newNavController release];
            shouldScrollToBottom = NO;
        }
    }
}

- (void)newTweetWithSender:(id)sender
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
    ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];

    [self newTweetForObjectID:[chatData objectID]];
}

- (void)tweet:(NSMutableDictionary*)params
{
    if([self.twitter isAuthorized])
    {
        NSString *caption = [params valueForKey:@"caption"];
        NSString *url = [params valueForKey:@"url"];
        NSString *key = [params valueForKey:@"key"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldConfirmCrossPost" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:key, @"key", @"TWT", @"postType", nil]];

        NSString *requestId = [self.twitter sendUpdate:[NSString stringWithFormat:@"%@ %@", caption, url]];
        [self addToTwitterQueue:requestId forKey:key];
    }
}

#pragma mark - facebook
- (void)postFBFeedForObject:(NSManagedObjectID*)objectID
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"touchFBFromChatView"];
    
    // show FB Auth if user is not signed in
    if(!FBSession.activeSession.isOpen)
    {
        [appDelegate openSessionWithAllowLoginUI:YES withPermissions:appDelegate.defaultPermissions];
    }
    else
    {
        ChatData *chatData = (ChatData*)[appDelegate.mainMOC objectWithID:objectID];
        ImageData *imageData = [chatData valueForKey:@"imageData"];
        
        if([[imageData valueForKey:@"url"] isEqualToString:@""] || [imageData valueForKey:@"url"] == nil)
        {
            [self didTouchThumbnailForObject:[chatData objectID] showMap:NO];
        }
        else
        {
            if(nil == self.facebook)
            {
                self.facebook = [[[Facebook alloc] initWithAppId:FBSession.activeSession.appID andDelegate:nil] autorelease];
                
                // Store the Facebook session information
                self.facebook.accessToken = FBSession.activeSession.accessToken;
                self.facebook.expirationDate = FBSession.activeSession.expirationDate;
            }
            
            NSMutableDictionary *fbParams = [[NSMutableDictionary alloc] init];
            
            SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
            
            NSString *imageURL = [NSString stringWithFormat:@"http://%@/viewPhoto/downloadImage/%@", appDelegate.apiHost, [chatData valueForKey:@"key"]];
            
            self.selectedKey = [chatData valueForKey:@"key"];
            
            NSString *firstName = [matchData valueForKey:@"firstName"];
            
            NSMutableString *caption = [[NSMutableString alloc] initWithFormat:@"%@", [matchData valueForKey:@"cityName"]];
            [caption appendFormat:@", %@", [matchData valueForKey:@"countryName"]];
            
            [fbParams setValue:[NSString stringWithFormat:@"%@'s photo on Wander", firstName] forKey:@"name"];
            [fbParams setValue:imageURL forKey:@"picture"];
            [fbParams setValue:caption forKey:@"caption"];
            [fbParams setValue:[imageData valueForKey:@"url"] forKey:@"link"];
            [fbParams setValue:@"photo" forKey:@"type"];
            
            [caption release];
            
            [self.facebook dialog:@"feed" andParams:fbParams andDelegate:self];
            [fbParams release];
            [jsonWriter release];
        }
    }
}

- (void)postFBFeedWithSender:(id)sender
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
    ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];

    [self postFBFeedForObject:[chatData objectID]];
}

- (void)postToFB:(NSMutableDictionary*)params
{
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    FBRequest *request = [FBRequest requestWithGraphPath:@"me/feed" parameters:params HTTPMethod:@"POST"];
    [connection addRequest:request completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error)
     {
         if (!error)
         {
             [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldConfirmCrossPost" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.selectedKey, @"key", @"FB", @"postType", nil]];

             NSString *key = [params valueForKey:@"meta"];
             
             if([self.facebookSharePool objectForKey:key])
             {
                 [self.facebookSharePool removeObjectForKey:key];
             }
         }
         else
         {
             UIAlertView *alertView = [[[UIAlertView alloc]
                                        initWithTitle:@"Error"
                                        message:error.localizedDescription
                                        delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil] autorelease];
             [alertView show];
         }
     }];
    [connection start];
    [connection autorelease];
}

#pragma mark - table view helper
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *key = [chatData valueForKey:@"key"];
    
	int senderNo = [[chatData valueForKey:@"sender"] intValue];
	int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
	bool isImage = [[chatData valueForKey:@"isImage"] boolValue];
    
	UIView *customCell = [cell.contentView viewWithTag:100];
    
    CGRect newCellFrame = customCell.frame;
    newCellFrame.size.width = self._tableView.frame.size.width;
    [customCell setFrame:newCellFrame];
    [customCell setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin];

	if(isImage == NO)
	{
		// insert the message and resize the text view
		UITextView *messageTextView = (UITextView*)[customCell viewWithTag:3];
        CGRect newTextFrame;
        CGFloat textWidth;
        CGFloat textHeight;

        CUIButton *contextMenuButton = (CUIButton*)[customCell viewWithTag:30];

        if([self.translationPool containsObject:key])
        {
            textWidth = [self getTextWidth:@"translating..."];
            textHeight = [self getTextHeight:@"translating..."];
            
            newTextFrame = messageTextView.frame;
            newTextFrame.size.width = textWidth + 20;
            newTextFrame.size.height = textHeight + 5;
            [messageTextView setFrame:newTextFrame];
            [messageTextView setTextColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
            [messageTextView setText:@"translating..."];
        }
        else
        {
            if([self.translatedMessages valueForKey:key])
            {
                textWidth = [self getTextWidth:[self.translatedMessages valueForKey:key]];
                textHeight = [self getTextHeight:[self.translatedMessages valueForKey:key]];
                
                newTextFrame = messageTextView.frame;
                newTextFrame.size.width = textWidth + 20;
                newTextFrame.size.height = textHeight + 5;
                [messageTextView setFrame:newTextFrame];
                [messageTextView setTextColor:[UIColor colorWithWhite:0.0 alpha:1.0]];
                [messageTextView setText:[self.translatedMessages valueForKey:key]];
            }
            else
            {
                textWidth = [[chatData valueForKey:@"textWidth"] floatValue];
                textHeight = [[chatData valueForKey:@"textHeight"] floatValue];
                
                newTextFrame = messageTextView.frame;
                newTextFrame.size.width = textWidth + 20;
                newTextFrame.size.height = textHeight + 5;
                [messageTextView setFrame:newTextFrame];
                [messageTextView setTextColor:[UIColor colorWithWhite:0.0 alpha:1.0]];
                [messageTextView setText:[chatData valueForKey:@"message"]];

                if(memberNo != senderNo)
                {                    
                    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
                    NSArray *languages = [defs objectForKey:@"AppleLanguages"];
                    NSString *preferredLang = [languages objectAtIndex:0];

                    UIImageView *translateIcon = (UIImageView*)[customCell viewWithTag:40];
                    UILabel *translateLabel = (UILabel*)[customCell viewWithTag:41];
                    if(![preferredLang isEqualToString:[chatData valueForKey:@"detectedLanguage"]] && [appDelegate.prefs boolForKey:@"didShowContextMenu"] == NO)
                    {
                        [translateIcon setHidden:NO];

                        if(textWidth < 95)
                        {
                            [translateLabel setHidden:YES];
                        }
                        else
                        {
                            [translateLabel setHidden:NO];
                        }
                        
                        UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
                        [tapGR setNumberOfTapsRequired:1];
                        [contextMenuButton addGestureRecognizer:tapGR];
                        [tapGR release];
                    }
                    else
                    {
                        [translateIcon setHidden:YES];
                        [translateLabel setHidden:YES];
                    }
                }
            }
        }

        [contextMenuButton setFrame:newTextFrame];
        
        UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [longPressGR setMinimumPressDuration:0.4];
        [contextMenuButton addGestureRecognizer:longPressGR];
        [longPressGR release];

        UITapGestureRecognizer *doubleTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        [doubleTapGR setNumberOfTapsRequired:2];
        [contextMenuButton addGestureRecognizer:doubleTapGR];
        [doubleTapGR release];
        
		// resize chat bubble
		UIView *chatBubble = (UIView*)[customCell viewWithTag:7];
		CGRect newBubbleFrame = chatBubble.frame;
		if(textWidth + 26 >= 69)
		{
			newBubbleFrame.size.width = textWidth + 26;

			if(senderNo == memberNo)
			{
				CGFloat newX = self._tableView.frame.size.width - (47 + textWidth + 26);
				newBubbleFrame.origin.x = newX;
			}
		}
		else
		{
			if(senderNo == memberNo)
			{
				newBubbleFrame.origin.x = self._tableView.frame.size.width - 116;
			}
			newBubbleFrame.size.width = 69;
		}
        
        // reposition thumbnail
        if(senderNo == memberNo)
        {
            UIImageView *profileImageView = (UIImageView*)[customCell viewWithTag:2];
            CGRect newProileImageFrame = profileImageView.frame;
            newProileImageFrame.origin.x = (self._tableView.frame.size.width - 45);
            [profileImageView setFrame:newProileImageFrame];
        }
        
		if(textHeight + 25 >= 41)
		{
			newBubbleFrame.size.height = textHeight + 25;
		}
		else
		{
			newBubbleFrame.size.height = 41;
		}
		[chatBubble setFrame:newBubbleFrame];
		
		UILabel *dateLabel = (UILabel*)[customCell viewWithTag:4];
		
		if([chatData valueForKey:@"datetime"] != nil)
		{
			NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
			[dateFormat setDateFormat:@"h:mm a"];
			
			NSDate* sourceDate = [chatData valueForKey:@"datetime"];
            
			NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
			NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
			
			NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
			NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
			NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
			
			NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
            
			[dateLabel setText:[dateFormat stringFromDate:destinationDate]];
            
			[destinationDate release];
			[dateFormat release];
		}
		else
		{
			[dateLabel setText:@""];
		}
		
		// set status indicators
		int status = [[chatData valueForKey:@"status"] intValue];
		UIButton *actionButton = (UIButton*)[customCell viewWithTag:5];
		[actionButton setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
		[actionButton addTarget:self action:@selector(showOptions:) forControlEvents:UIControlEventTouchUpInside];
        
		UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[customCell viewWithTag:6];
        
		if((status == 1 && [spool containsObject:key]) || [self.translationPool containsObject:key])
		{
			[actionButton setHidden:YES];
			[spinner setHidden:NO];
			[spinner startAnimating];
		}
		else if(status == 1 && ![spool containsObject:key])
		{
			[actionButton setHidden:NO];
			[spinner setHidden:YES];
			[spinner stopAnimating];
		}
		else if(status == 0)
		{
			[actionButton setHidden:YES];
			[spinner setHidden:YES];
			[spinner stopAnimating];
		}
	}
	else
	{
		// get status indicators
		int status = [[chatData valueForKey:@"status"] intValue];
		UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[customCell viewWithTag:4];
		UIButton *actionButton = (UIButton*)[customCell viewWithTag:7];
		[actionButton setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
		[actionButton addTarget:self action:@selector(showOptions:) forControlEvents:UIControlEventTouchUpInside];
        
        // get share buttons
        CUIButton *fbButton = nil;
        CUIButton *tweetButton = nil;
        if(senderNo != memberNo)
        {
            fbButton = (CUIButton*)[customCell viewWithTag:11];
            [fbButton addTarget:self action:@selector(postFBFeedWithSender:) forControlEvents:UIControlEventTouchUpInside];
            [fbButton setAlpha:0.5];
            [fbButton setEnabled:NO];
            
            tweetButton = (CUIButton*)[customCell viewWithTag:22];
            [tweetButton addTarget:self action:@selector(newTweetWithSender:) forControlEvents:UIControlEventTouchUpInside];
            [tweetButton setAlpha:0.5];
            [tweetButton setEnabled:NO];
        }
        
		UIProgressView *progressView = (UIProgressView*)[customCell viewWithTag:8];
        
        UIView *variableContainer = [customCell viewWithTag:50];
        
		// get image
		UIImageView *photoImage = (UIImageView*)[variableContainer viewWithTag:3];
		[photoImage setImage:nil];

		[actionButton setHidden:YES];

		// set thumbnail
		if([chatData valueForKey:@"thumbnailFile"] != nil)
		{
            [self.photoCache removeObjectForKey:key];
            
            if([self.photoDataCache objectForKey:key])
            {
                [photoImage setImage:[self.photoDataCache objectForKey:key]];
            }
            else
            {
                // if the cache is at the limit, remove one old object at a time
                if([self.photoDataCache count] >= MAX_CACHED_IMAGES)
                {
                    id oldCacheKey = [[self.photoDataCache allKeys] objectAtIndex:0];
                    [self.photoDataCache removeObjectForKey:oldCacheKey];
                }
                
                NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:[chatData valueForKey:@"thumbnailFile"]];            
                UIImage *photo = [UIImage imageFromFile:imagePath];
                
                if(photo != nil)
                {
                    [photoImage setImage:photo];
                    
                    // add photo to cache
                    [self.photoDataCache setObject:photo forKey:key];
                    
                    if(senderNo != memberNo)
                    {
                        if(receivedPhotoCount < 3)
                        {
                            receivedPhotoCount = receivedPhotoCount + 1;
                        }
                    }
                }
            }

            if(receivedPhotoCount == 3 && sharePromptIsVisable == NO && [appDelegate.prefs boolForKey:@"didShowSharePrompt"] == NO)
            {
                receivedPhotoCount = 0;
                sharePromptIsVisable = YES;
                
                [self.sharePromptBubble.layer setMasksToBounds:YES];
                [self.sharePromptBubble.layer setCornerRadius:8.0];
                
                [self.sharePromptView setFrame:CGRectMake(50, 40, self.sharePromptView.frame.size.width, self.sharePromptView.frame.size.height)];
                [customCell addSubview:self.sharePromptView];
                [self.sharePromptView setAlpha:0.0];
                
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                [UIView setAnimationDuration:0.2f];
                [self.sharePromptView setAlpha:1.0];
                [UIView commitAnimations];
                
                [appDelegate.prefs setBool:YES forKey:@"didShowSharePrompt"];
                [appDelegate.prefs synchronize];
            }
            
            if(fbButton != nil && tweetButton != nil)
            {
                [fbButton setAlpha:1.0];
                [fbButton setEnabled:YES];
                
                [tweetButton setAlpha:1.0];
                [tweetButton setEnabled:YES];
            }
		}
		else if([self.photoCache objectForKey:key])
		{
			UIImage *cachedImage = [self.photoCache objectForKey:key];
			[photoImage setImage:cachedImage];
		}
        else
        {
            //status = 1;
        }

        ImageData *imageDataObject = [chatData valueForKey:@"imageData"];
		if(senderNo == memberNo)
		{
            // re-download
            if(status == 0 && [chatData valueForKey:@"thumbnailFile"] == nil)
            {
                [progressView setProgress:0];
                [progressView setHidden:NO];
                [actionButton setHidden:YES];
                [spinner setHidden:NO];
                [spinner startAnimating];
                
                [self addObjectIDToDownloadPool:[chatData objectID] forKey:key];
                [self downloadThumbnail:[chatData valueForKey:@"messageNo"] withProgressView:progressView];
            }
            // upload
			else if(status == 1 && [uploadPool valueForKey:key])
			{
                [progressView setHidden:NO];
                [actionButton setHidden:YES];
                [spinner setHidden:NO];
                [spinner startAnimating];
                [photoImage setAlpha:0.5];

				if([imageDataObject valueForKey:@"imageFile"] != nil)
				{
                    NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:[imageDataObject valueForKey:@"imageFile"]];
					NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
					if(imageDataObject != nil)
					{
                        [progressView setProgress:0];
						[self sendPhoto:imageDataObject withImageData:imageData withProgressView:progressView];
					}
				}
			}
			else if(status == 1)
			{
				[progressView setHidden:YES];
				[actionButton setHidden:NO];
				[spinner setHidden:YES];
				[spinner stopAnimating];
			}
            else
            {
                [progressView setHidden:YES];
                [spinner setHidden:YES];
                [spinner stopAnimating];
                [photoImage setAlpha:1.0];
            }
		}
        // download
        else
        {
            if([chatData valueForKey:@"thumbnailFile"] == nil)
            {
                [progressView setHidden:NO];
                [actionButton setHidden:YES];
                [spinner setHidden:NO];
                [spinner startAnimating];
                
                if(![downloadPool valueForKey:key])
                {
                    [progressView setProgress:0];
                    [self addObjectIDToDownloadPool:[chatData objectID] forKey:key];
                    [self downloadThumbnail:[chatData valueForKey:@"messageNo"] withProgressView:progressView];
                }
            }
            else
            {
                [progressView setHidden:YES];
                [spinner setHidden:YES];
                [spinner stopAnimating];
                [photoImage setAlpha:1.0];
            }
        }
        
        // set caption
        float captionHeight = 0;
        UILabel *captionLabel = (UILabel*)[variableContainer viewWithTag:55];
        if(![[imageDataObject valueForKey:@"caption"] isEqualToString:@""] && [imageDataObject valueForKey:@"caption"] != nil)
        {
            NSString *caption = [imageDataObject valueForKey:@"caption"];
            captionHeight = [[imageDataObject valueForKey:@"captionHeight"] floatValue];
            [captionLabel setFrame:CGRectMake(captionLabel.frame.origin.x, captionLabel.frame.origin.y, captionLabel.frame.size.width, captionHeight)];
            
            [variableContainer setFrame:CGRectMake(variableContainer.frame.origin.x, variableContainer.frame.origin.y, variableContainer.frame.size.width, 140 + captionHeight)];
            
            if(captionHeight != 0)
            {
                [captionLabel setText:caption];
            }
        }
        else
        {
            [captionLabel setText:@""];
            
            [variableContainer setFrame:CGRectMake(variableContainer.frame.origin.x, variableContainer.frame.origin.y, variableContainer.frame.size.width, 140)];
        }
        
        CUIButton *subButton = (CUIButton*)[customCell viewWithTag:62];
        [subButton.superview setFrame:CGRectMake(0, 0, subButton.superview.frame.size.width, 180 + captionHeight)];

        // resize chat bubble
        UIView *chatBubble = (UIView*)[customCell viewWithTag:9];
        CGRect newBubbleFrame = chatBubble.frame;
        newBubbleFrame.size.height = 172 + captionHeight + 4;
        [chatBubble setFrame:newBubbleFrame];
        
        // set location
        UIImageView *locationPip = (UIImageView*)[customCell viewWithTag:60];
        UILabel *locationLabel = (UILabel*)[customCell viewWithTag:61];
        if(status == 0)
        {
            [locationPip setHidden:NO];
            [locationLabel setHidden:NO];
            NSString *cityName = [imageDataObject valueForKey:@"cityName"];
            if(![cityName isEqualToString:@""] && cityName != nil)
            {
                NSString *locationName = [imageDataObject valueForKey:@"locationName"];
                
                if(![locationName isEqualToString:@""] && locationName != nil)
                {
                    [locationLabel setText:[NSString stringWithFormat:@"%@, %@", locationName, cityName]];
                }
                else
                {
                    [locationLabel setText:[NSString stringWithFormat:@"near %@", cityName]];
                }
            }
            else
            {
                if([[chatData valueForKey:@"sender"] intValue] == [appDelegate.prefs integerForKey:@"memberNo"])
                {
                    [locationLabel setText:[NSString stringWithFormat:@"near %@", [appDelegate.prefs valueForKey:@"cityName"]]];
                }
                else
                {
                    [locationLabel setText:[NSString stringWithFormat:@"near %@", [matchData valueForKey:@"cityName"]]];
                }
            }
            
            [subButton setFrame:CGRectMake(subButton.frame.origin.x, 155 + captionHeight, subButton.frame.size.width, subButton.frame.size.height)];
            [subButton setUserInteractionEnabled:YES];
            
            // set mission
            UIImageView *missionIcon = (UIImageView*)[customCell viewWithTag:70];
            UILabel *missionLabel = (UILabel*)[customCell viewWithTag:71];
            if(status == 0 && ![[imageDataObject valueForKey:@"mission"] isEqualToString:@""] && [imageDataObject valueForKey:@"mission"] != nil)
            {
                NSString *mission = [imageDataObject valueForKey:@"mission"];
                [missionLabel setText:mission];
                [missionIcon setHidden:NO];
                [missionLabel setHidden:NO];
                
                [subButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents]; 
                [subButton addTarget:self action:@selector(didTouchMission:) forControlEvents:UIControlEventTouchUpInside];
                
                [locationPip setHidden:YES];
                [locationLabel setHidden:YES];
            }
            else
            {
                [missionIcon setHidden:YES];
                [missionLabel setHidden:YES];
                
                [subButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                [subButton addTarget:self action:@selector(didTouchLocation:) forControlEvents:UIControlEventTouchUpInside];
                
                [locationPip setHidden:NO];
                [locationLabel setHidden:NO];
            }
        }
        else
        {
            [locationPip setHidden:YES];
            [locationLabel setHidden:YES];
        }
        
		UILabel *dateLabel = (UILabel*)[customCell viewWithTag:6];
		if([chatData valueForKey:@"datetime"] != nil)
		{
			NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
			[dateFormat setDateFormat:@"h:mm a"];
			
			NSDate* sourceDate = [chatData valueForKey:@"datetime"];
			
			NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
			NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
			
			NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
			NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
			NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
			
			NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
            
			[dateLabel setText:[dateFormat stringFromDate:destinationDate]];
			
			[destinationDate release];
			[dateFormat release];
		}
		else
		{
			[dateLabel setText:@""];
		}
	}
}

#pragma mark - UITableView data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
	int senderNo = [[chatData valueForKey:@"sender"] intValue];
	int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
	bool isImage = [[chatData valueForKey:@"isImage"] boolValue];
	
	static NSString *leftChatCellId = @"leftChat";
	static NSString *rightChatCellId = @"rightChat";
	static NSString *leftPhotoCellId = @"leftPhoto";
	static NSString *rightPhotoCellId = @"rightPhoto";
	NSString *CellIdentifier = @"";
	
	if(isImage == NO)
	{
		if(senderNo == memberNo)
		{
			CellIdentifier = rightChatCellId;
		}
		else
		{
			CellIdentifier = leftChatCellId;
		}
	}
	else if(isImage == YES)
	{
		if(senderNo == memberNo)
		{
			CellIdentifier = rightPhotoCellId;
		}
		else
		{
			CellIdentifier = leftPhotoCellId;
		}
	}
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
        UIView *cellView = nil;
        if(isImage == NO)
        {
            if(senderNo == memberNo)
            {
                cellView = [self rightMessageCell];
            }
            else
            {
                cellView = [self leftMessageCell:senderNo];
            }
        }
        else if(isImage == YES)
        {
            if(senderNo == memberNo)
            {
                cellView = [self rightPhotoCell];
            }
            else
            {
                cellView = [self leftPhotoCell:senderNo];
            }
        }

        [cellView setTag:100];

        [cell setAutoresizesSubviews:YES];
        [cell.contentView setAutoresizesSubviews:YES];
        [cell.contentView addSubview:cellView];

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    CGRect newCellFrame = cell.frame;
    newCellFrame.size.width = tableView.frame.size.width;
    
    [cell setFrame:newCellFrame];
    [cell.contentView setFrame:newCellFrame];

    [self configureCell:cell atIndexPath:indexPath];
    
	return cell;
}

#pragma mark - UITableView delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [chatInput resignFirstResponder];
    if(translationPromptIsVisable == YES) [self dismissTranslationPrompt];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    return;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(self._tableView.contentOffset.y < -30 && nextPageExists == YES)
    {
        [self.loadMoreLabel setHidden:YES];
        [self.loadingLabel setHidden:NO];
        [self.loadingSpinner startAnimating];
        
        [self._tableView setContentInset:UIEdgeInsetsMake(30, 0, 0, 0)];
        
        [self performSelector:@selector(getMoreMessages) withObject:nil afterDelay:0.1];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    return;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 60.0f;
	ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *key = [chatData valueForKey:@"key"];
    
	if([[chatData valueForKey:@"isImage"] intValue] == 0)
	{
        CGFloat textHeight = 0;
        if([self.translatedMessages valueForKey:key])
        {
            NSString *translatedMessage = [self.translatedMessages valueForKey:key];
            textHeight = [self getTextHeight:translatedMessage];
        }
        else
        {
            textHeight = [[chatData valueForKey:@"textHeight"] floatValue];
        }

        // top and bottom margin
        textHeight += 43.0f;
        result = MAX(textHeight, 60.0f);
	}
	else
	{
        ImageData *imageDataForKey = [chatData valueForKey:@"imageData"];

        float addHeight = 0;
        if(imageDataForKey != nil)
        {
            if(![[imageDataForKey valueForKey:@"caption"] isEqualToString:@""] && [imageDataForKey valueForKey:@"caption"] != nil)
            {
                float captionHeight = [[imageDataForKey valueForKey:@"captionHeight"] floatValue];
                addHeight += captionHeight + 4;
            }
        }

        result = 180 + addHeight;
	}
    
	int lastSection = [self numberOfSectionsInTableView:self._tableView] - 1;
	int lastRowInLastSection = [self tableView:_tableView numberOfRowsInSection:lastSection] - 1;
	NSIndexPath *lastRow = [NSIndexPath indexPathForRow:lastRowInLastSection inSection:lastSection];
    
	if(lastRow.section == indexPath.section && lastRow.row == indexPath.row)
	{
		result += 44;
	}
	
	return result;
}

#pragma mark - fetched result controller delegates
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	// The fetch controller is about to start sending change notifications, so prepare the table view for updates.
	[self._tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	UITableView *tableView = self._tableView;
    
    if(type == NSFetchedResultsChangeInsert)
    {
        UITableViewRowAnimation animation;
        ChatData *chatData = [controller objectAtIndexPath:newIndexPath];
        if([[chatData valueForKey:@"sender"] intValue] == [appDelegate.prefs integerForKey:@"memberNo"])
        {
            animation = UITableViewRowAnimationRight;
        }
        else
        {
            animation = UITableViewRowAnimationLeft;
        }
        
        [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:animation];
    }
    
    if(shouldScrollToBottom == YES)
    {
        receivedNewMessage = YES;
    }

	switch(type)
    {
		case NSFetchedResultsChangeDelete:
            shouldScrollToBottom = NO;
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
            shouldScrollToBottom = NO;
			[self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;
			
		case NSFetchedResultsChangeMove:
            shouldScrollToBottom = NO;
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	switch(type)
    {
		case NSFetchedResultsChangeInsert:
			[self._tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self._tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	// The fetch controller has sent all current change notifications, so tell the table view to process all updates.
	[self._tableView endUpdates];

    [self performSelectorOnMainThread:@selector(updateChatTable) withObject:nil waitUntilDone:NO];
}

#pragma mark - action sheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];

	if(actionSheet.tag == 0)
	{
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            if(buttonIndex == 0)
            {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                [picker setDelegate:self];
                [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
                [self presentModalViewController:picker animated:YES];
                [picker.navigationBar resizeBGLayer:CGRectMake(0, 0, 320, 44)];
                [picker release];
            }
            else if(buttonIndex == 1 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                [picker setDelegate:self];
                [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [self presentModalViewController:picker animated:YES];
                [picker.navigationBar resizeBGLayer:CGRectMake(0, 0, 320, 44)];
                [picker release];
            }
        }
        else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
        {
            if(buttonIndex == 0)
            {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                [picker setDelegate:self];
                [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [picker.navigationBar setCustomBGLayer:CGRectMake(0, 0, 320, 44)];
                [self presentModalViewController:picker animated:YES];
                [picker release];
            }
        }
        shouldScrollToBottom = NO;
	}
	else if(actionSheet.tag == 1)
	{
		ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
		// delete the message
		if(buttonIndex == 0)
		{
			[chatData setValue:nil forKey:@"key"];
			[chatData setValue:nil forKey:@"datetime"];
            
			[appDelegate saveContext:appDelegate.mainMOC];
		}
		// resend the message
		else if(buttonIndex == 1)
		{
			NSString *key = [chatData valueForKey:@"key"];
            
			if([[chatData valueForKey:@"isImage"] intValue] == 0)
			{
				[self addToTextPool:key];
                [self reloadIndexPath:indexPath];
                
				NSString *message = [chatData valueForKey:@"message"];
                QueueMessageOperation *queueMessageOperation = [[QueueMessageOperation alloc] initWithMatchData:matchData andMessage:message resendWithObject:chatData];
                [queueMessageOperation setThreadPriority:1.0];
                [self.operationQueue addOperation:queueMessageOperation];
                [queueMessageOperation release];
			}
			else
			{
				[self addObjectIDToUploadPool:[chatData objectID] forKey:key];
				[self addToResendPool:key];
				[self._tableView reloadData];
			}
		}
	}
    else if(actionSheet.tag == 10)
    {
        if(buttonIndex == 0)
        {
            ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
            
            if(![[chatData valueForKey:@"message"] isEqualToString:@""])
            {
                UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
                [pasteBoard setValue:[chatData valueForKey:@"message"] forPasteboardType:@"public.utf8-plain-text"];
            }
        }
        else if(buttonIndex == 1)
        {
            NSInvocationOperation *translateOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(translateText:) object:indexPath];
            [translateOperation setThreadPriority:1.0];
            [self.translateOperationQueue addOperation:translateOperation];
            [translateOperation release];
        }
    }
    else if(actionSheet.tag == 20)
    {
        ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSString *key = [chatData valueForKey:@"key"];
        
        if(buttonIndex == 0)
        {
            if(![[chatData valueForKey:@"message"] isEqualToString:@""])
            {
                UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
                [pasteBoard setValue:[chatData valueForKey:@"message"] forPasteboardType:@"public.utf8-plain-text"];
            }
        }
        else if(buttonIndex == 1)
        {
            // remove translation
            [self.translatedMessages removeObjectForKey:key];
            [self reloadIndexPath:indexPath];
        }
    }
    else if(actionSheet.tag == 30)
    {
        ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        if(buttonIndex == 0)
        {
            if(![[chatData valueForKey:@"message"] isEqualToString:@""])
            {
                UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
                [pasteBoard setValue:[chatData valueForKey:@"message"] forPasteboardType:@"public.utf8-plain-text"];
            }
        }
    }
}

#pragma mark - image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
	if(CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo)
	{
        UIImage *originalImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] && [info objectForKey:@"UIImagePickerControllerReferenceURL"])
        {
            [appDelegate showLoading];
            
            NSDictionary *pushData = [NSDictionary dictionaryWithObjectsAndKeys:
                                      picker, @"picker",
                                      originalImage, @"image",
                                      [NSNumber numberWithBool:NO], @"shouldSaveToCameraRoll",
                                      [NSNumber numberWithInt:UIImagePickerControllerSourceTypePhotoLibrary], @"sourceType",
                                      nil];
            
            [self performSelector:@selector(pushShareControllerWithData:) withObject:pushData afterDelay:0.0];
        }
        else
        {
            [appDelegate showLoading];
            
            NSDictionary *pushData = [NSDictionary dictionaryWithObjectsAndKeys:
                                      picker, @"picker",
                                      originalImage, @"image",
                                      [NSNumber numberWithBool:YES], @"shouldSaveToCameraRoll",
                                      [NSNumber numberWithInt:UIImagePickerControllerSourceTypeCamera], @"sourceType",
                                      nil];
            
            [self performSelector:@selector(pushShareControllerWithData:) withObject:pushData afterDelay:0.0];
        }
	}
}

#pragma mark - twitter delegate
- (void)storeCachedTwitterOAuthData:(NSString *)data forUsername:(NSString *)username
{
	[appDelegate.prefs setObject:data forKey:@"TwitterAuthData"];
	[appDelegate.prefs synchronize];
}

- (NSString *)cachedTwitterOAuthDataForUsername:(NSString *)username
{
	return [appDelegate.prefs objectForKey:@"TwitterAuthData"];
}

- (void)OAuthTwitterController:(SA_OAuthTwitterController *)controller authenticatedWithUsername:(NSString *)username
{
	[appDelegate.prefs setObject:username forKey:@"twitterId"];
    [appDelegate.prefs synchronize];
	shouldLoadTweet = YES;
}

- (void)OAuthTwitterControllerFailed:(SA_OAuthTwitterController *)controller
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"twitterDidCancel" object:nil];
}

- (void)OAuthTwitterControllerCanceled:(SA_OAuthTwitterController *)controller
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"twitterDidCancel" object:nil];
}

- (void) requestSucceeded: (NSString *) requestIdentifier
{
    if([self.twitterQueue valueForKey:requestIdentifier])
    {
        NSString *key = [self.twitterQueue valueForKey:requestIdentifier];
        [self.twitterQueue removeObjectForKey:requestIdentifier];
        [self.twitterSharePool removeObjectForKey:key];
    }
}

- (void) requestFailed:(NSString *)requestIdentifier withError: (NSError *) error
{
    if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
    {
        NSLog(@"tweet error: %@", error);
    }
}

#pragma mark - facebook helpers
- (void)handleFBLogin
{    
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error)
     {
         if (!error)
         {
             [self handleFBRequest:user];
         }
     }];
}

- (void)handleFBRequest:(NSDictionary<FBGraphUser>*)user
{
    NSString *facebookID = user.id;
    [appDelegate.prefs setValue:facebookID forKey:@"fbId"];
    [appDelegate.prefs synchronize];
    
    NSIndexPath *indexPath = [self._tableView indexPathForCell:self.selectedCell];
    ChatData *chatData = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self performSelectorOnMainThread:@selector(postFBFeedForObject:) withObject:[chatData objectID] waitUntilDone:NO];
}

#pragma mark - facebook delegate
- (void)sessionStateChanged:(NSNotification*)notification
{
    if(FBSession.activeSession.isOpen)
    {
        [self handleFBLogin];
    }
}

- (void)dialogDidComplete:(FBDialog *)dialog
{
    return;
}

- (void)dialogCompleteWithUrl:(NSURL *)url
{
    // hack for facebook bug
    if(![[NSString stringWithFormat:@"%@", url] isEqualToString:@"fbconnect://success"])
    {
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"postPhotoToFB"];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldConfirmCrossPost" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.selectedKey, @"key", @"FB", @"postType", nil]];
    }
}

#pragma mark - mission controller, share photo controller delegate
- (void)resetNavControllerWithData:(NSDictionary *)data
{
    [self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:NO afterDelay:0.0];
    [self performSelector:@selector(showShareViewController:) withObject:data afterDelay:0.0];
}

- (void)didHitBackFromShareView:(UIImagePickerControllerSourceType)sourceType
{
    [self dismissModalViewControllerAnimated:NO];

    id pickerDelegate = [self.navigationController topViewController];

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    if([pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingMediaWithInfo:)])
    {
        [picker setDelegate:pickerDelegate];
    }
    else
    {
        [picker setDelegate:self];
    }
    [picker setSourceType:sourceType];
    [self presentModalViewController:picker animated:NO];
    [picker.navigationBar resizeBGLayer:CGRectMake(0, 0, 320, 44)];
    [picker release];
    shouldScrollToBottom = NO;
}

- (void)queuePhoto:(UIImage*)image withKey:(NSString*)key andMetaData:(NSDictionary*)metaData saveToCameraRoll:(bool)save
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldPopToChatView" object:nil userInfo:nil];
    
    // send photo            
    QueuePhotoOperation *queuePhotoOperation = [[QueuePhotoOperation alloc] initWithMatchData:matchData withKey:key andImage:image saveToCameralRoll:save];
    [queuePhotoOperation setThreadPriority:1.0];
    [queuePhotoOperation setMetaData:metaData];
    [self.operationQueue addOperation:queuePhotoOperation];
    [queuePhotoOperation release];
}

#pragma mark - ASIHTTPReqeust delegate
- (void)didReceiveJson:(NSDictionary*)jsonObject andHeaders:(NSDictionary*)headers
{
    // if task was send photo
    if([[jsonObject valueForKey:@"task"] isEqualToString:@"sendPhoto"])
    {
        NSMutableDictionary *apiResult = [NSMutableDictionary dictionaryWithDictionary:[jsonObject objectForKey:@"result"]];
        
        if([apiResult count] > 0)
        {
            if([[apiResult valueForKey:@"messageNo"] intValue] != 0)
            {
                NSString *key = [apiResult valueForKey:@"key"];
                NSManagedObjectID *objectID = [uploadPool valueForKey:key];
                
                NSMutableDictionary *results = [NSMutableDictionary dictionary];
                [results setValue:apiResult forKey:@"apiResult"];
                [results setValue:objectID forKey:@"objectID"];

                [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldConfirmSentMessage" object:nil userInfo:results];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldUpdatePartnerData" object:nil userInfo:results];
            }
        }
    }
}

- (void)didReceiveBinary:(NSData*)data andHeaders:(NSDictionary*)headers
{
    // if task was download photo get message number
    int messageNo = [[headers objectForKey:@"X-Yongopal-Messageno"] intValue];
    
    // and key
    NSString *key = [headers objectForKey:@"X-Yongopal-Key"];
    
    // and short url
    NSString *shortUrl = [headers objectForKey:@"X-Yongopal-Shorturl"];

    if([data length] > 0)
    {
        // hand over downloaded photo
        UIImage *downloadedImage = [UIImage imageWithData:data];
        NSDictionary *photoData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   downloadedImage, @"imageData",
                                   [NSNumber numberWithInt:messageNo], @"messageNo",
                                   key, @"key",
                                   shortUrl, @"url", nil];
        
        NSInvocationOperation *thumbOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setThumbnailData:) object:photoData];
        [thumbOperation setThreadPriority:1.0];
        [self.receiveOperationQueue addOperation:thumbOperation];
        [thumbOperation release];
        [photoData release];
    }
    else if([downloadPool valueForKey:key] && [[retryPool valueForKey:key] intValue] < 3)
    {
        if(![retryPool valueForKey:key])
        {
            [self addToRetryPool:[NSNumber numberWithInt:1] forKey:key];
        }
        else
        {
            int retryCount = [[retryPool valueForKey:key] intValue];
            retryCount++;
            [retryPool setValue:[NSNumber numberWithInt:retryCount] forKey:key];
        }

        NSManagedObjectID *objectID = [downloadPool valueForKey:key];
        ChatData *chatData = (ChatData*)[appDelegate.mainMOC objectWithID:objectID];
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:chatData];
        UITableViewCell *cell = [self._tableView cellForRowAtIndexPath:indexPath];
        UIView *customCell = [cell.contentView viewWithTag:100];
        UIProgressView *progressView = (UIProgressView*)[customCell viewWithTag:8];
        [progressView setProgress:0];
        [progressView setHidden:NO];

        [self downloadThumbnail:chatData.messageNo withProgressView:progressView];
    }
    else
    {
        [retryPool removeObjectForKey:key];
        [downloadPool removeObjectForKey:key];
    }
}

#pragma mark - image picker navigation controller delegate
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
}

#pragma mark - keyboard notification handlers
- (void)keyboardWillShow:(NSNotification *)noif
{
    if(keyboardIsVisible == NO)
    {
        originalTableHeight = self._tableView.frame.size.height;
        originalChatBarY = self.chatBarView.frame.origin.y;
    }
    keyboardIsVisible = YES;

    // get keyboard size and loctaion
	CGRect keyboardBounds;
    [[noif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
	
	// get the height since this is the main value that we need.
	NSInteger kbSizeH = keyboardBounds.size.height;
    if(kbSizeH == [UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO])
    {
        kbSizeH = keyboardBounds.size.width;
    }

    // get a rect for the textView frame
	CGRect chatBarFrame = chatBarView.frame;
	chatBarFrame.origin.y = originalChatBarY - kbSizeH;

    // get a rect for the textView frame
	CGRect tableFrame = self._tableView.frame;
	tableFrame.size.height = originalTableHeight - kbSizeH;

	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.25f];
	
	// set views with new info
	self.chatBarView.frame = chatBarFrame;
    self._tableView.frame = tableFrame;
	
	// commit animations
	[UIView commitAnimations];
    
    // scroll to bottom
	[self scrollToBottomWithAnimation:YES];
}

-(void)keyboardWillHide:(NSNotification *)noif
{
    if(keyboardIsVisible == NO)
    {
        return;
    }
    keyboardIsVisible = NO;
    
    // get keyboard size and location
	CGRect keyboardBounds;
    [[noif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
	
	// get the height since this is the main value that we need.
	NSInteger kbSizeH = keyboardBounds.size.height;
    if(kbSizeH == [UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO])
    {
        kbSizeH = keyboardBounds.size.width;
    }
	
	// get a rect for the textView frame
	CGRect chatBarFrame = chatBarView.frame;
	chatBarFrame.origin.y += kbSizeH;
	
	// get a rect for the tableView frame
	CGRect tableFrame = self._tableView.frame;
	tableFrame.size.height += kbSizeH;
	
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.2f];
	
	// set views with new info
	self.chatBarView.frame = chatBarFrame;
	self._tableView.frame = tableFrame;
    
	// commit animations
	[UIView commitAnimations];
}

#pragma mark - thread notification handlers
- (void)checkNewMessages:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:NO];
        return;
    }

    CheckNewMessageOperation *checkNewMessageOperation = [[CheckNewMessageOperation alloc] initWithMatchData:matchData];
    [checkNewMessageOperation setThreadPriority:0.1];
    [self.syncOperationQueue addOperation:checkNewMessageOperation];
    [checkNewMessageOperation release];
}

- (void)getNewMessages:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:NO];
        return;
    }

    ReceiveMessageOperation *receiveMessageOperation = [[ReceiveMessageOperation alloc] initWithMatchData:matchData];
    [receiveMessageOperation setThreadPriority:0.1];
    [self.receiveOperationQueue addOperation:receiveMessageOperation];
    [receiveMessageOperation release];
}

- (void)sendMessageToServer:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:NO];
        return;
    }
    
    NSDictionary *result = [noif userInfo];    
    SendMessageOperation *sendMessageOperation = [[SendMessageOperation alloc] initWithRequestData:[result valueForKey:@"requestData"] andObjectID:[result valueForKey:@"objectID"]];
    [sendMessageOperation setThreadPriority:1.0];
    [self.sendOperationQueue addOperation:sendMessageOperation];
    [sendMessageOperation release];
}

- (void)confirmSentMessages:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:NO];
        return;
    }

    NSDictionary *result = [noif userInfo];    
    ConfirmSentOperation *confirmSentOperation = [[ConfirmSentOperation alloc] initWithResults:[result valueForKey:@"apiResult"] withObjectID:[result valueForKey:@"objectID"] ];
    [confirmSentOperation setThreadPriority:1.0];
    [confirmSentOperation setFacebookSharePool:self.facebookSharePool];
    [confirmSentOperation setTwitterSharePool:self.twitterSharePool];
    [self.sendOperationQueue addOperation:confirmSentOperation];
    [confirmSentOperation release];
}

- (void)updatePartnerData:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:NO];
        return;
    }

    NSDictionary *data = [[noif userInfo] valueForKey:@"apiResult"];
    if([data valueForKey:@"city"] && [data valueForKey:@"city"] != [NSNull null]) [matchData setValue:[data valueForKey:@"city"] forKey:@"cityName"];
	if([data valueForKey:@"country"] && [data valueForKey:@"country"] != [NSNull null]) [matchData setValue:[data valueForKey:@"country"] forKey:@"countryName"];
    if([data valueForKey:@"timezoneOffset"] && [data valueForKey:@"timezoneOffset"] != [NSNull null]) [matchData setValue:[NSNumber numberWithInt:[[data valueForKey:@"timezoneOffset"] intValue]] forKey:@"timezoneOffset"];
    if([data valueForKey:@"update"] && [data valueForKey:@"update"] != [NSNull null]) [matchData setValue:[NSNumber numberWithInt:[[data valueForKey:@"update"] intValue]] forKey:@"update"];
	[appDelegate saveContext:appDelegate.mainMOC];
}

- (void)setSentPhotoThumbnail:(NSNotification*)noif
{
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    NSDictionary *data = [noif userInfo];
    NSData *thumbnail = [data valueForKey:@"thumbnail"];
    NSString *key = [data valueForKey:@"key"];

    // fetch and set chat data
	NSFetchRequest *request = [[NSFetchRequest alloc] init];    
    NSEntityDescription *chatEntity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:threadContext];
    [request setEntity:chatEntity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key = %@", key];
	[request setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [threadContext executeFetchRequest:request error:&error];
	[request release];
    
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}

	if([fetchedObjects count] > 0)
	{
		ChatData *chatObject = [fetchedObjects objectAtIndex:0];
        NSString *thumbnailFile = [UtilityClasses saveImageData:thumbnail named:@"thumbnail" withKey:key overwrite:YES];
        [chatObject setValue:thumbnailFile forKey:@"thumbnailFile"];
        [appDelegate saveContext:threadContext];
	}
}

- (void)addKeyToTextPool:(NSNotification*)noif
{
    NSDictionary *data = [noif userInfo];
    [self performSelectorOnMainThread:@selector(addToTextPool:) withObject:[data valueForKey:@"key"] waitUntilDone:YES];
}

- (void)addKeyToUploadPool:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:YES];
        return;
    }

    NSDictionary *data = [noif userInfo];
    [self addObjectIDToUploadPool:[data valueForKey:@"objectID"] forKey:[data valueForKey:@"key"]];
}

- (void)postToFBWithKey:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:NO];
        return;
    }

    NSDictionary *data = [noif userInfo];
    NSString *key = [data valueForKey:@"key"];
    self.selectedKey = key;

    NSMutableDictionary *fbParams = [self.facebookSharePool objectForKey:key];
    [fbParams setObject:key forKey:@"meta"];
    [self postToFB:fbParams];
}

- (void)tweetWithKey:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:NO];
        return;
    }

    NSDictionary *data = [noif userInfo];
    NSString *key = [data valueForKey:@"key"];
    
    NSMutableDictionary *twParams = [self.twitterSharePool objectForKey:key];
    [twParams setValue:key forKey:@"key"];
    
    [self tweet:twParams];
}

- (void)removeKey:(NSNotification*)noif
{
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    NSDictionary *data = [noif userInfo];
    NSString *key = [data valueForKey:@"key"];
    NSNumber *messageNo = [data valueForKey:@"messageNo"];
    NSString *url = [data valueForKey:@"url"];
    
    if([spool containsObject:key])
    {
        [spool performSelectorOnMainThread:@selector(removeObject:) withObject:key waitUntilDone:YES];
    }
    
    if([uploadPool valueForKey:key])
    {
        // fetch and set image data
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *imageEntity = [NSEntityDescription entityForName:@"ImageData" inManagedObjectContext:threadContext];
        [request setEntity:imageEntity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key = %@", key];
        [request setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [threadContext executeFetchRequest:request error:&error];
        
        if(fetchedObjects == nil)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }

        if([fetchedObjects count] > 0)
        {
            ImageData *imageObject = [fetchedObjects objectAtIndex:0];
            [imageObject setValue:messageNo forKey:@"messageNo"];
            [imageObject setValue:url forKey:@"url"];
            [appDelegate saveContext:threadContext];
        }
        [request release];

        [uploadPool performSelectorOnMainThread:@selector(removeObjectForKey:) withObject:key waitUntilDone:NO];
    }
}

- (void)scrollToBottomAnimated:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:YES];
        return;
    }

    shouldScrollToBottom = YES;
}

- (void)reloadTableData:(NSNotification*)noif
{
    [self._tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)dismissModalView:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:YES];
        return;
    }

    [self dismissModalViewControllerAnimated:YES];
    [appDelegate hideLoading];
    [self._tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
}

- (void)setPhotoCache:(NSNotification*)noif
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:noif waitUntilDone:YES];
        return;
    }

    NSDictionary *data = [noif userInfo];
    [self.photoCache setObject:[data valueForKey:@"photo"] forKey:[data valueForKey:@"key"]];
}

#pragma mark - growing textview delegate
- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
	float textDiff = (chatInput.frame.size.height - height);
    
	CGRect newBarViewFrame = chatBarView.frame;
	newBarViewFrame.size.height -= textDiff;
	newBarViewFrame.origin.y += textDiff;
	chatBarView.frame = newBarViewFrame;
	
	CGRect newBarFrame = chatBar.frame;
	newBarFrame.size.height -= textDiff;
	chatBar.frame = newBarFrame;
}

#pragma mark - table cells
- (UIView*)leftMessageCell:(int)sender
{
	UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 65)];
	[cell setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
	[cell setBackgroundColor:[UIColor clearColor]];
	
	UIButton *backgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[backgroundButton setFrame:CGRectMake(0, 0, 320, 65)];
	[backgroundButton setBackgroundColor:[UIColor clearColor]];
	[backgroundButton addTarget:chatInput action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
	[backgroundButton setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
	[backgroundButton setTag:1];
	
	UIImageView *profileThumb = [[UIImageView alloc] initWithFrame:CGRectMake(5, 7, 40, 40)];
	[profileThumb setImage:self.partnerProfileImage];
	[profileThumb.layer setMasksToBounds:YES];
	[profileThumb.layer setCornerRadius:5];
	[profileThumb setTag:2];
    
    UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 7, 40, 40)];
    [profileButton addTarget:self action:@selector(loadProfile) forControlEvents:UIControlEventTouchUpInside];
    [profileButton setBackgroundColor:[UIColor clearColor]];
	
	UIView* shadowView = [[UIView alloc] init];
    /*
     [shadowView.layer setCornerRadius:5.0];
     [shadowView.layer setShadowColor:[[UIColor blackColor] CGColor]];
     [shadowView.layer setShadowOffset:CGSizeMake(1.0f, 1.0f)];
     [shadowView.layer setShadowOpacity:0.7f];
     [shadowView.layer setShadowRadius:1.0f];
     */
	[shadowView addSubview:profileThumb];
    
    CUIButton *contextMenuButton = [[CUIButton alloc] initWithFrame:CGRectMake(5, 3, 20, 25)];
    [contextMenuButton setTag:30];
    [contextMenuButton setBackgroundColor:[UIColor clearColor]];
    
	UITextView *messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(5, 3, 20, 25)];
	[messageTextView setContentInset:UIEdgeInsetsMake(-4.0, 0, 0, 0)];
	[messageTextView setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0]];
	[messageTextView setBackgroundColor:[UIColor clearColor]];
	[messageTextView setScrollEnabled:NO];
	[messageTextView setEditable:NO];
    [messageTextView setUserInteractionEnabled:NO];
	[messageTextView setTag:3];
	
	UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 63, 13)];
	[dateLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:10.0]];
	[dateLabel setTextAlignment:UITextAlignmentRight];
	[dateLabel setBackgroundColor:[UIColor clearColor]];
	[dateLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
	[dateLabel setTextColor:UIColorFromRGB(0xbbbbbb)];
	[dateLabel setTag:4];
    
    UIImageView *translateIcon = [[UIImageView alloc] initWithFrame:CGRectMake(11, 26, 6, 9)];
    [translateIcon setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [translateIcon setImage:[UIImage imageNamed:@"ico_tinytranslate.png"]];
    [translateIcon setTag:40];
    [translateIcon setHidden:YES];
    
    UILabel *translateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 24, 38, 14)];
    [translateLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
    [translateLabel setMinimumFontSize:10.0];
	[translateLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:12.0]];
	[translateLabel setTextAlignment:UITextAlignmentLeft];
	[translateLabel setBackgroundColor:[UIColor clearColor]];
	[translateLabel setTextColor:UIColorFromRGB(0x00bfde)];
    [translateLabel setText:@"translate"];
	[translateLabel setTag:41];
    [translateLabel setHidden:YES];
	
	UIImageView *topLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_topleft_L.png"]];
	[topLeft setFrame:CGRectMake(0, 0, 15, 30)];
	
	UIView *top = [[UIView alloc] initWithFrame:CGRectMake(15, 0, 44, 30)];
	[top setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_top.png"]]];
	[top.layer setOpaque:NO];
	top.opaque = NO;
	[top setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	
	UIImageView *topRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_topright_L.png"]];
	[topRight setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[topRight setFrame:CGRectMake(59, 0, 15, 30)];
	
	UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 15, 1)];
	[left setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_left.png"]]];
	[left.layer setOpaque:NO];
	left.opaque = NO;
	[left setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
	
	UIView *middle = [[UIView alloc] initWithFrame:CGRectMake(15, 30, 44, 1)];
	[middle setBackgroundColor:[UIColor whiteColor]];
	[middle setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	
	UIView *right = [[UIView alloc] initWithFrame:CGRectMake(59, 30, 15, 1)];
	[right setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_right.png"]]];
	[right.layer setOpaque:NO];
	right.opaque = NO;
	[right setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin];
	
	UIImageView *bottomLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bottomleft.png"]];
	[bottomLeft setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	[bottomLeft setFrame:CGRectMake(0, 31, 15, 10)];
	
	UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(15, 31, 44, 10)];
	[bottom setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_bottom.png"]]];
	[bottom.layer setOpaque:NO];
	bottom.opaque = NO;
	[bottom setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
	
	UIImageView *bottomRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bottomright.png"]];
	[bottomRight setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin];
	[bottomRight setFrame:CGRectMake(59, 31, 15, 10)];
	
	UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(47, 7, 69, 41)];
	[messageView setBackgroundColor:[UIColor clearColor]];
	[messageView setAutoresizesSubviews:YES];
	[messageView addSubview:topLeft];
	[messageView addSubview:top];
	[messageView addSubview:topRight];
	[messageView addSubview:left];
	[messageView addSubview:middle];
	[messageView addSubview:right];
	[messageView addSubview:bottomLeft];
	[messageView addSubview:bottom];
	[messageView addSubview:bottomRight];
	[messageView addSubview:messageTextView];
    [messageView addSubview:contextMenuButton];
	[messageView addSubview:dateLabel];
    [messageView addSubview:translateIcon];
    [messageView addSubview:translateLabel];
	[messageView setTag:7];
    
	UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[actionButton setImage:[UIImage imageNamed:@"ico_failed.png"] forState:UIControlStateNormal];
	[actionButton setFrame:CGRectMake(272, 10, 40, 40)];
	[actionButton setAutoresizingMask:UIViewAutoresizingNone];
	[actionButton setTag:5];
    [actionButton setHidden:YES];
	
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(282, 20, 20, 20)];
	[spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	[spinner setTag:6];
	
	[cell addSubview:backgroundButton];
	[cell addSubview:shadowView];
    [cell addSubview:profileButton];
	[cell addSubview:messageView];
	[cell addSubview:actionButton];
	[cell addSubview:spinner];
	
	[topLeft release];
	[top release];
	[topRight release];
	[left release];
	[middle release];
	[right release];
	[bottomLeft release];
	[bottom release];
	[bottomRight release];
	[shadowView release];
    [profileButton release];
	[messageView release];
	
	[profileThumb release];
	[messageTextView release];
    [contextMenuButton release];
	[dateLabel release];
    [translateIcon release];
    [translateLabel release];
	[spinner release];
	
	return [cell autorelease];
}

- (UIView*)rightMessageCell
{
	UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self._tableView.frame.size.width, 65)];
	[cell setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin];
	[cell setBackgroundColor:[UIColor clearColor]];
    [cell setAutoresizesSubviews:YES];
    
	UIButton *backgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[backgroundButton setFrame:CGRectMake(0, 0, 320, 65)];
	[backgroundButton setBackgroundColor:[UIColor clearColor]];
	[backgroundButton addTarget:chatInput action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
	[backgroundButton setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
	[backgroundButton setTag:1];
    
	UIImageView *profileThumb = [[UIImageView alloc] initWithFrame:CGRectMake((self._tableView.frame.size.width - 45), 7, 40, 40)];
    [profileThumb setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[profileThumb setImage:self.userProfileImage];
	[profileThumb.layer setMasksToBounds:YES];
	[profileThumb.layer setCornerRadius:5];
	[profileThumb setTag:2];
	
    CUIButton *contextMenuButton = [[CUIButton alloc] initWithFrame:CGRectMake(5, 3, 20, 25)];
    [contextMenuButton setTag:30];
    [contextMenuButton setBackgroundColor:[UIColor clearColor]];
    
	UITextView *messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(5, 3, 20, 25)];
	[messageTextView setContentInset:UIEdgeInsetsMake(-4.0, 0, 0, 0)];
	[messageTextView setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0]];
	[messageTextView setBackgroundColor:[UIColor clearColor]];
	[messageTextView setScrollEnabled:NO];
	[messageTextView setEditable:NO];
    [messageTextView setUserInteractionEnabled:NO];
	[messageTextView setTag:3];
    
	UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 58, 13)];
	[dateLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:10.0]];
	[dateLabel setTextAlignment:UITextAlignmentRight];
	[dateLabel setBackgroundColor:[UIColor clearColor]];
	[dateLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
	[dateLabel setTextColor:UIColorFromRGB(0xbbbbbb)];
	[dateLabel setTag:4];
	
	UIImageView *topLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_topleft_R.png"]];
	[topLeft setFrame:CGRectMake(0, 0, 15, 30)];
    
	UIView *top = [[UIView alloc] initWithFrame:CGRectMake(15, 0, 39, 30)];
	[top setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_top.png"]]];
	[top.layer setOpaque:NO];
	top.opaque = NO;
	[top setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
	UIImageView *topRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_topright_R.png"]];
	[topRight setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[topRight setFrame:CGRectMake(54, 0, 15, 30)];
    
	UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 15, 1)];
	[left setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_left.png"]]];
	[left.layer setOpaque:NO];
	left.opaque = NO;
	[left setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    
	UIView *middle = [[UIView alloc] initWithFrame:CGRectMake(15, 30, 39, 1)];
	[middle setBackgroundColor:[UIColor whiteColor]];
	[middle setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    
	UIView *right = [[UIView alloc] initWithFrame:CGRectMake(54, 30, 15, 1)];
	[right setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_right.png"]]];
	[right.layer setOpaque:NO];
	right.opaque = NO;
	[right setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin];
    
	UIImageView *bottomLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bottomleft.png"]];
	[bottomLeft setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	[bottomLeft setFrame:CGRectMake(0, 31, 15, 10)];
    
	UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(15, 31, 39, 10)];
	[bottom setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_bottom.png"]]];
	[bottom.layer setOpaque:NO];
	bottom.opaque = NO;
	[bottom setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
	
	UIImageView *bottomRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bottomright.png"]];
	[bottomRight setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin];
	[bottomRight setFrame:CGRectMake(54, 31, 15, 10)];
	
	UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake((self._tableView.frame.size.width - 116), 7, 69, 41)];
    [messageView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[messageView setBackgroundColor:[UIColor clearColor]];
	[messageView setAutoresizesSubviews:YES];
	[messageView addSubview:topLeft];
	[messageView addSubview:top];
	[messageView addSubview:topRight];
	[messageView addSubview:left];
	[messageView addSubview:middle];
	[messageView addSubview:right];
	[messageView addSubview:bottomLeft];
	[messageView addSubview:bottom];
	[messageView addSubview:bottomRight];
	[messageView addSubview:messageTextView];
    [messageView addSubview:contextMenuButton];
	[messageView addSubview:dateLabel];
	[messageView setTag:7];
	
	UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[actionButton setImage:[UIImage imageNamed:@"ico_failed.png"] forState:UIControlStateNormal];
	[actionButton setFrame:CGRectMake(10, 9, 40, 40)];
	[actionButton setAutoresizingMask:UIViewAutoresizingNone];
	[actionButton setTag:5];
    [actionButton setHidden:YES];
	
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 20, 20, 20)];
	[spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	[spinner setTag:6];

	[cell addSubview:backgroundButton];
	[cell addSubview:profileThumb];
	[cell addSubview:messageView];
	[cell addSubview:actionButton];
	[cell addSubview:spinner];
	
	[topLeft release];
	[top release];
	[topRight release];
	[left release];
	[middle release];
	[right release];
	[bottomLeft release];
	[bottom release];
	[bottomRight release];
	[messageView release];
    
	[profileThumb release];
	[messageTextView release];
    [contextMenuButton release];
	[dateLabel release];
	[spinner release];
	
	return [cell autorelease];
}

- (UIView*)leftPhotoCell:(int)sender
{
	UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 180)];
	[cell setBackgroundColor:[UIColor clearColor]];
    
	UIButton *backgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[backgroundButton setFrame:CGRectMake(0, 0, 320, 180)];
	[backgroundButton setBackgroundColor:[UIColor clearColor]];
	[backgroundButton addTarget:chatInput action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
	[backgroundButton setTag:1];
    
	UIImageView *profileThumb = [[UIImageView alloc] initWithFrame:CGRectMake(5, 7, 40, 40)];
	[profileThumb setImage:self.partnerProfileImage];
	[profileThumb.layer setMasksToBounds:YES];
	[profileThumb.layer setCornerRadius:5];
	[profileThumb setTag:2];
    
    UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 7, 40, 40)];
    [profileButton addTarget:self action:@selector(loadProfile) forControlEvents:UIControlEventTouchUpInside];
    [profileButton setBackgroundColor:[UIColor clearColor]];
    
	UIView* shadowView = [[UIView alloc] init];
    /*
     [shadowView.layer setCornerRadius:5.0];
     [shadowView.layer setShadowColor:[[UIColor blackColor] CGColor]];
     [shadowView.layer setShadowOffset:CGSizeMake(1.0f, 1.0f)];
     [shadowView.layer setShadowOpacity:0.7f];
     [shadowView.layer setShadowRadius:1.0f];
     */
	[shadowView addSubview:profileThumb];
    
    
    UIImage *fbImage = [UIImage imageNamed:@"btn_fb.png"];
    UIImage *fbOnImage = [UIImage imageNamed:@"btn_fb-on.png"];
    UIImage *tweetImage = [UIImage imageNamed:@"btn_tweet.png"];
    UIImage *tweetOnImage = [UIImage imageNamed:@"btn_tweet-on.png"];
    
    CUIButton *fbButton = [[CUIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [fbButton setHitErrorMargin:5];
    [fbButton setBackgroundImage:fbImage forState:UIControlStateNormal];
    [fbButton setBackgroundImage:fbOnImage forState:UIControlEventTouchDown];
    [fbButton setTag:11];
    
    CUIButton *tweetButton = [[CUIButton alloc] initWithFrame:CGRectMake(0, 41, 40, 40)];
    [tweetButton setHitErrorMargin:5];
    [tweetButton setBackgroundImage:tweetImage forState:UIControlStateNormal];
    [tweetButton setBackgroundImage:tweetOnImage forState:UIControlEventTouchDown];
    [tweetButton setTag:22];
    
    UIView *sharePanel = [[UIView alloc] initWithFrame:CGRectMake(5, 57, 40, 81)];
    /*
     [sharePanel.layer setCornerRadius:5.0];
     [sharePanel setBackgroundColor:[UIColor whiteColor]];
     [sharePanel.layer setShadowColor:[[UIColor blackColor] CGColor]];
     [sharePanel.layer setShadowOffset:CGSizeMake(1.0f, 1.0f)];
     [sharePanel.layer setShadowOpacity:0.7f];
     [sharePanel.layer setShadowRadius:1.0f];
     */
    [sharePanel addSubview:fbButton];
    [sharePanel addSubview:tweetButton];
    [fbButton release];
    [tweetButton release];
    
	UIImageView *photoImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 185, 140)];
	[photoImage setImage:nil];
	[photoImage setContentMode:UIViewContentModeScaleAspectFill];
	[photoImage setClipsToBounds:YES];
	[photoImage setBackgroundColor:[UIColor whiteColor]];
	[photoImage.layer setMasksToBounds:YES];
	[photoImage.layer setCornerRadius:5];
	[photoImage setTag:3];

	CUIButton *photoButton = [CUIButton buttonWithType:UIButtonTypeCustom];
	[photoButton setFrame:CGRectMake(10, 7, 185, 140)];
	[photoButton setBackgroundColor:[UIColor clearColor]];
	[photoButton addTarget:self action:@selector(didTouchThumbnail:) forControlEvents:UIControlEventTouchUpInside];
	[photoButton setTag:5];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(95, 67, 20, 20)];
	[spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	[spinner setTag:4];
    
    UILabel *captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 143, 180, 0)];
    [captionLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0]];
    [captionLabel setBackgroundColor:[UIColor clearColor]];
    [captionLabel setLineBreakMode:UILineBreakModeWordWrap];
    [captionLabel setNumberOfLines:9999];
    [captionLabel setTag:55];
    
    UIView *variableContainer = [[UIView alloc] initWithFrame:CGRectMake(10, 7, 185, 140)];
    [variableContainer setBackgroundColor:[UIColor clearColor]];
    [variableContainer setTag:50];
    [variableContainer addSubview:photoImage];
    [variableContainer addSubview:photoButton];
    [variableContainer addSubview:captionLabel];
    [photoImage release];
    [captionLabel release];
    
    UIImageView *locationPip = [[UIImageView alloc] initWithFrame:CGRectMake(11, 150, 6, 9)];
    [locationPip setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [locationPip setImage:[UIImage imageNamed:@"tinypipgray.png"]];
    [locationPip setTag:60];
    
    UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 147, 135, 14)];
    [locationLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [locationLabel setMinimumFontSize:10.0];
	[locationLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:12.0]];
	[locationLabel setTextAlignment:UITextAlignmentLeft];
	[locationLabel setBackgroundColor:[UIColor clearColor]];
	[locationLabel setTextColor:UIColorFromRGB(0xbbbbbb)];
	[locationLabel setTag:61];
    
    CUIButton *subButton = [[CUIButton alloc] initWithFrame:CGRectMake(57, 155, 136, 20)];
    [subButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [subButton setHitErrorMargin:10];
    [subButton setBackgroundColor:[UIColor clearColor]];
    [subButton setTag:62];
    
    UIImageView *missionIcon = [[UIImageView alloc] initWithFrame:CGRectMake(11, 150, 7, 8)];
    [missionIcon setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [missionIcon setHidden:YES];
    [missionIcon setImage:[UIImage imageNamed:@"ico_tinymission.png"]];
    [missionIcon setTag:70];
    
    UILabel *missionLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 147, 135, 14)];
    [missionLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [missionLabel setHidden:YES];
    [missionLabel setMinimumFontSize:10.0];
	[missionLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:12.0]];
	[missionLabel setTextAlignment:UITextAlignmentLeft];
	[missionLabel setBackgroundColor:[UIColor clearColor]];
	[missionLabel setTextColor:UIColorFromRGB(0x00bfde)];
	[missionLabel setTag:71];
    
	UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 149, 194, 13)];
	[dateLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:10.0]];
	[dateLabel setTextAlignment:UITextAlignmentRight];
	[dateLabel setBackgroundColor:[UIColor clearColor]];
	[dateLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	[dateLabel setTextColor:UIColorFromRGB(0xbbbbbb)];
	[dateLabel setTag:6];
    
	UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[actionButton setImage:[UIImage imageNamed:@"ico_failed.png"] forState:UIControlStateNormal];
	[actionButton setFrame:CGRectMake(270, 70, 40, 40)];
	[actionButton setAutoresizingMask:UIViewAutoresizingNone];
	[actionButton setTag:7];
    [actionButton setHidden:YES];
    
	UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, 150, 185, 11)];
    [progressView setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	[progressView setProgressViewStyle:UIProgressViewStyleBar];
	[progressView setProgress:0];
	[progressView setTag:8];
    
	UIImageView *topLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_topleft_L.png"]];
	[topLeft setFrame:CGRectMake(0, 0, 15, 30)];
    
	UIView *top = [[UIView alloc] initWithFrame:CGRectMake(15, 0, 176, 30)];
	[top setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_top.png"]]];
	[top.layer setOpaque:NO];
	top.opaque = NO;
	[top setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
	UIImageView *topRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_topright_L.png"]];
	[topRight setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[topRight setFrame:CGRectMake(191, 0, 15, 30)];
    
	UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 15, 125)];
	[left setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_left.png"]]];
	[left.layer setOpaque:NO];
	left.opaque = NO;
	[left setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    
	UIView *middle = [[UIView alloc] initWithFrame:CGRectMake(15, 30, 176, 125)];
	[middle setBackgroundColor:[UIColor whiteColor]];
	[middle setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    
	UIView *right = [[UIView alloc] initWithFrame:CGRectMake(191, 30, 15, 125)];
	[right setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_right.png"]]];
	[right.layer setOpaque:NO];
	right.opaque = NO;
	[right setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin];
    
	UIImageView *bottomLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bottomleft.png"]];
	[bottomLeft setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	[bottomLeft setFrame:CGRectMake(0, 155, 15, 10)];
    
	UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(15, 155, 176, 10)];
	[bottom setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_bottom.png"]]];
	[bottom.layer setOpaque:NO];
	bottom.opaque = NO;
	[bottom setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
    
	UIImageView *bottomRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bottomright.png"]];
	[bottomRight setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin];
	[bottomRight setFrame:CGRectMake(191, 155, 15, 10)];
    
	UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(47, 7, 206, 172)];
	[messageView setBackgroundColor:[UIColor clearColor]];
	[messageView setAutoresizesSubviews:YES];
	[messageView addSubview:topLeft];
	[messageView addSubview:top];
	[messageView addSubview:topRight];
	[messageView addSubview:left];
	[messageView addSubview:middle];
	[messageView addSubview:right];
	[messageView addSubview:bottomLeft];
	[messageView addSubview:bottom];
	[messageView addSubview:bottomRight];
    [messageView addSubview:variableContainer];
    [messageView addSubview:missionIcon];
    [messageView addSubview:missionLabel];
    [messageView addSubview:locationPip];
    [messageView addSubview:locationLabel];
	[messageView addSubview:dateLabel];
	[messageView addSubview:progressView];
	[messageView addSubview:spinner];
	[messageView setTag:9];
    
	[cell addSubview:backgroundButton];
	[cell addSubview:shadowView];
    [cell addSubview:profileButton];
    [cell addSubview:sharePanel];
	[cell addSubview:messageView];
	[cell addSubview:actionButton];
    [cell addSubview:subButton];
    
	[topLeft release];
	[top release];
	[topRight release];
	[left release];
	[middle release];
	[right release];
	[bottomLeft release];
	[bottom release];
	[bottomRight release];
    [variableContainer release];
    [missionIcon release];
    [missionLabel release];
	[shadowView release];
    [profileButton release];
    [sharePanel release];
	[messageView release];
    
	[profileThumb release];
	[spinner release];
    [locationPip release];
    [locationLabel release];
    [subButton release];
	[dateLabel release];
	[progressView release];
    
	return [cell autorelease];
}

- (UIView*)rightPhotoCell
{
	UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self._tableView.frame.size.width, 180)];
    [cell setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin];
	[cell setBackgroundColor:[UIColor clearColor]];
    [cell setAutoresizesSubviews:YES];
    
	UIButton *backgroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[backgroundButton setFrame:CGRectMake(0, 0, 320, 180)];
	[backgroundButton setBackgroundColor:[UIColor clearColor]];
	[backgroundButton addTarget:chatInput action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
	[backgroundButton setTag:1];
    
    UIImageView *profileThumb = [[UIImageView alloc] initWithFrame:CGRectMake((self._tableView.frame.size.width - 45), 7, 40, 40)];
    [profileThumb setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[profileThumb setImage:self.userProfileImage];
	[profileThumb.layer setMasksToBounds:YES];
	[profileThumb.layer setCornerRadius:5];
	[profileThumb setTag:2];
    
	UIImageView *photoImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 185, 140)];
	[photoImage setImage:nil];
	[photoImage setContentMode:UIViewContentModeScaleAspectFill];
	[photoImage setClipsToBounds:YES];
	[photoImage setBackgroundColor:[UIColor whiteColor]];
	[photoImage.layer setMasksToBounds:YES];
	[photoImage.layer setCornerRadius:5];
	[photoImage setTag:3];
    
	CUIButton *photoButton = [CUIButton buttonWithType:UIButtonTypeCustom];
	[photoButton setFrame:CGRectMake(10, 7, 185, 140)];
	[photoButton setBackgroundColor:[UIColor clearColor]];
	[photoButton addTarget:self action:@selector(didTouchThumbnail:) forControlEvents:UIControlEventTouchUpInside];
	[photoButton setTag:5];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(95, 67, 20, 20)];
	[spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	[spinner setTag:4];
    
    UILabel *captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 143, 180, 0)];
    [captionLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0]];
    [captionLabel setBackgroundColor:[UIColor clearColor]];
    [captionLabel setLineBreakMode:UILineBreakModeWordWrap];
    [captionLabel setNumberOfLines:9999];
    [captionLabel setTag:55];
    
    UIView *variableContainer = [[UIView alloc] initWithFrame:CGRectMake(10, 7, 185, 140)];
    [variableContainer setBackgroundColor:[UIColor clearColor]];
    [variableContainer setTag:50];
    [variableContainer addSubview:photoImage];
    [variableContainer addSubview:photoButton];
    [variableContainer addSubview:captionLabel];
    [photoImage release];
    [captionLabel release];
    
    UIImageView *locationPip = [[UIImageView alloc] initWithFrame:CGRectMake(11, 150, 6, 9)];
    [locationPip setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [locationPip setImage:[UIImage imageNamed:@"tinypipgray.png"]];
    [locationPip setTag:60];
    
    UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 147, 135, 14)];
    [locationLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [locationLabel setMinimumFontSize:10.0];
	[locationLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:12.0]];
	[locationLabel setTextAlignment:UITextAlignmentLeft];
	[locationLabel setBackgroundColor:[UIColor clearColor]];
	[locationLabel setTextColor:UIColorFromRGB(0xbbbbbb)];
	[locationLabel setTag:61];
    
    CUIButton *subButton = [[CUIButton alloc] initWithFrame:CGRectMake(79, 155, 136, 20)];
    [subButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin];
    [subButton setHitErrorMargin:10];
    [subButton setBackgroundColor:[UIColor clearColor]];
    [subButton setTag:62];
    
    UIImageView *missionIcon = [[UIImageView alloc] initWithFrame:CGRectMake(11, 150, 7, 8)];
    [missionIcon setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [missionIcon setHidden:YES];
    [missionIcon setImage:[UIImage imageNamed:@"ico_tinymission.png"]];
    [missionIcon setTag:70];
    
    UILabel *missionLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 147, 135, 14)];
    [missionLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [missionLabel setHidden:YES];
    [missionLabel setMinimumFontSize:10.0];
	[missionLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:12.0]];
	[missionLabel setTextAlignment:UITextAlignmentLeft];
	[missionLabel setBackgroundColor:[UIColor clearColor]];
	[missionLabel setTextColor:UIColorFromRGB(0x00bfde)];
	[missionLabel setTag:71];
    
	UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 149, 194, 13)];
	[dateLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:10.0]];
	[dateLabel setTextAlignment:UITextAlignmentRight];
	[dateLabel setBackgroundColor:[UIColor clearColor]];
	[dateLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	[dateLabel setTextColor:UIColorFromRGB(0xbbbbbb)];
	[dateLabel setTag:6];
    
	UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[actionButton setImage:[UIImage imageNamed:@"ico_failed.png"] forState:UIControlStateNormal];
	[actionButton setFrame:CGRectMake(10, 70, 40, 40)];
	[actionButton setAutoresizingMask:UIViewAutoresizingNone];
	[actionButton setTag:7];
    [actionButton setHidden:YES];
    
	UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(10, 150, 185, 11)];
    [progressView setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	[progressView setProgressViewStyle:UIProgressViewStyleBar];
	[progressView setProgress:0];
	[progressView setTag:8];
    
	UIImageView *topLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_topleft_R.png"]];
	[topLeft setFrame:CGRectMake(0, 0, 15, 30)];
    
	UIView *top = [[UIView alloc] initWithFrame:CGRectMake(15, 0, 176, 30)];
	[top setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_top.png"]]];
	[top.layer setOpaque:NO];
	top.opaque = NO;
	[top setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
	UIImageView *topRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_topright_R.png"]];
	[topRight setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[topRight setFrame:CGRectMake(191, 0, 15, 30)];
    
	UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 15, 125)];
	[left setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_left.png"]]];
	[left.layer setOpaque:NO];
	left.opaque = NO;
	[left setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    
	UIView *middle = [[UIView alloc] initWithFrame:CGRectMake(15, 30, 176, 125)];
	[middle setBackgroundColor:[UIColor whiteColor]];
	[middle setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    
	UIView *right = [[UIView alloc] initWithFrame:CGRectMake(191, 30, 15, 125)];
	[right setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_right.png"]]];
	[right.layer setOpaque:NO];
	right.opaque = NO;
	[right setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin];
    
	UIImageView *bottomLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bottomleft.png"]];
	[bottomLeft setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	[bottomLeft setFrame:CGRectMake(0, 155, 15, 10)];
    
	UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(15, 155, 176, 10)];
	[bottom setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"chat_bottom.png"]]];
	[bottom.layer setOpaque:NO];
	bottom.opaque = NO;
	[bottom setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
    
	UIImageView *bottomRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bottomright.png"]];
	[bottomRight setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin];
	[bottomRight setFrame:CGRectMake(191, 155, 15, 10)];

	UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake((self._tableView.frame.size.width - 251), 7, 206, 172)];
    [messageView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[messageView setBackgroundColor:[UIColor clearColor]];
	[messageView setAutoresizesSubviews:YES];
	[messageView addSubview:topLeft];
	[messageView addSubview:top];
	[messageView addSubview:topRight];
	[messageView addSubview:left];
	[messageView addSubview:middle];
	[messageView addSubview:right];
	[messageView addSubview:bottomLeft];
	[messageView addSubview:bottom];
	[messageView addSubview:bottomRight];
    [messageView addSubview:variableContainer];
    [messageView addSubview:missionIcon];
    [messageView addSubview:missionLabel];
    [messageView addSubview:locationPip];
    [messageView addSubview:locationLabel];
	[messageView addSubview:dateLabel];
	[messageView addSubview:progressView];
	[messageView addSubview:spinner];
	[messageView setTag:9];

	[cell addSubview:backgroundButton];
	[cell addSubview:profileThumb];
	[cell addSubview:messageView];
	[cell addSubview:actionButton];
    [cell addSubview:subButton];
    
	[topLeft release];
	[top release];
	[topRight release];
	[left release];
	[middle release];
	[right release];
	[bottomLeft release];
	[bottom release];
	[bottomRight release];
    [variableContainer release];
    [missionIcon release];
    [missionLabel release];
	[messageView release];
    
	[profileThumb release];
	[spinner release];
    [locationPip release];
    [locationLabel release];
    [subButton release];
	[dateLabel release];
	[progressView release];
    
	return [cell autorelease];
}

@end
