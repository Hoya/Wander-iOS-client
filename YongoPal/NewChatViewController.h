//
//  NewChatViewController.h
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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "YongoPalAppDelegate.h"
#import "ViewPhotoController.h"
#import "SharePhotoController.h"
#import "APIRequest.h"

#import "MissionViewControllerOld.h"

// twitter
#import "SA_OAuthTwitterEngine.h"
#import "SA_OAuthTwitterController.h"

// custom controls
#import "HPGrowingTextView.h"

// core data
#import "MatchData.h"
#import "ChatData.h"
#import "ImageData.h"

@interface NewChatViewController : UIViewController
<
    UITableViewDelegate,
    UITableViewDataSource,
    UINavigationControllerDelegate,
    UIActionSheetDelegate,
    NSFetchedResultsControllerDelegate,
    UIImagePickerControllerDelegate,
    HPGrowingTextViewDelegate,
    APIRequestDelegate,
    MGTwitterEngineDelegate,
    SA_OAuthTwitterEngineDelegate,
    SA_OAuthTwitterControllerDelegate,
    FBDialogDelegate,
    ViewPhotoControllerDeleagte,
    MissionViewOldDelegate,
    SharePhotoControllerDeleagte
>
{
    YongoPalAppDelegate *appDelegate;
    MatchData *matchData;
    SharePhotoController *shareController;
    NSTimer *navbarTimer;
    NSTimer *tapHoldTimer;
    NSString *selectedKey;
    NSIndexPath *lastIndexPath;
    
    APIRequest *apiRequest;
    NSOperationQueue *operationQueue;
    NSOperationQueue *translateOperationQueue;
    NSOperationQueue *syncOperationQueue;
    NSOperationQueue *sendOperationQueue;
    NSOperationQueue *receiveOperationQueue;
    
    Facebook *facebook;

    UITableView *_tableView;
    UIView *loadMoreView;
    UIView *loadMoreLabel;
    UIView *loadingLabel;
    UIActivityIndicatorView *loadingSpinner;
    HPGrowingTextView *chatInput;
    UIView *chatInputContainer;
    UIView *chatBarView;
    UIView *chatBar;
    UIButton *sendButton;
    UIImageView *shareSomething;
    UIView *welcomeView;
    UIView *welcomePrompt;
    UILabel *welcomeTitle;
    CUIButton *closeWelcomePromptButton;
    CUIButton *takePhotoButton;
    
    UIView *translatePromptView;
    UIView *translatePromptBubble;
    UIView *sharePromptView;
    UIView *sharePromptBubble;
    
    NSMutableArray *spool;
	NSMutableDictionary *uploadPool;
	NSMutableArray *resendPool;
    NSMutableDictionary *downloadPool;
    NSMutableDictionary *retryPool;
    NSMutableArray *translationPool;
    NSMutableDictionary *translatedMessages;
    NSMutableDictionary *facebookSharePool;
    NSMutableDictionary *twitterSharePool;
    NSMutableDictionary *twitterQueue;
    
    UITableViewCell *selectedCell;

    int matchNo;
    bool chatDisabled;
    bool showIntroPrompt;
    bool shouldLoadTweet;
    bool shouldScrollToBottom;
    bool receivedNewMessage;
    int maxListItems;
    bool keyboardIsVisible;
    bool translationPromptIsVisable;
    bool sharePromptIsVisable;
    bool nextPageExists;
    int receivedPhotoCount;
    int retryThread;
    
    float originalTableHeight;
    float originalChatBarY;
    id keyboard;
}

@property (nonatomic, retain) MatchData *matchData;
@property (nonatomic, retain) SharePhotoController *shareController;
@property (nonatomic, retain) NSString *selectedKey;
@property (nonatomic, retain) NSIndexPath *lastIndexPath;

@property (nonatomic, retain, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) APIRequest *apiRequest;
@property (nonatomic, retain, readonly) NSMutableDictionary *photoCache;
@property (nonatomic, retain, readonly) NSMutableDictionary *photoDataCache;
@property (nonatomic, retain) NSOperationQueue *operationQueue;
@property (nonatomic, retain) NSOperationQueue *translateOperationQueue;
@property (nonatomic, retain) NSOperationQueue *syncOperationQueue;
@property (nonatomic, retain) NSOperationQueue *sendOperationQueue;
@property (nonatomic, retain) NSOperationQueue *receiveOperationQueue;
@property (nonatomic, retain, readonly) SA_OAuthTwitterEngine *twitter;
@property (nonatomic, retain) Facebook *facebook;

@property (nonatomic, retain) NSMutableArray *spool;
@property (nonatomic, retain) NSMutableDictionary *uploadPool;
@property (nonatomic, retain) NSMutableArray *resendPool;
@property (nonatomic, retain) NSMutableDictionary *downloadPool;
@property (nonatomic, retain) NSMutableDictionary *retryPool;
@property (nonatomic, retain) NSMutableArray *translationPool;
@property (nonatomic, retain) NSMutableDictionary *translatedMessages;
@property (nonatomic, retain) NSMutableDictionary *facebookSharePool;
@property (nonatomic, retain) NSMutableDictionary *twitterSharePool;
@property (nonatomic, retain) NSMutableDictionary *twitterQueue;

@property (nonatomic, retain) UIImage *userProfileImage;
@property (nonatomic, retain) UIImage *partnerProfileImage;

@property (nonatomic, retain) IBOutlet UITableView *_tableView;
@property (nonatomic, retain) IBOutlet UIView *loadMoreView;
@property (nonatomic, retain) IBOutlet UIView *loadMoreLabel;
@property (nonatomic, retain) IBOutlet UIView *loadingLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, retain) HPGrowingTextView *chatInput;
@property (nonatomic, retain) IBOutlet UIView *chatInputContainer;
@property (nonatomic, retain) IBOutlet UIView *chatBarView;
@property (nonatomic, retain) IBOutlet UIView *chatBar;
@property (nonatomic, retain) IBOutlet UIButton *sendButton;
@property (nonatomic, retain) IBOutlet UIImageView *shareSomething;
@property (nonatomic, retain) IBOutlet UIView *welcomeView;
@property (nonatomic, retain) IBOutlet UIView *welcomePrompt;
@property (nonatomic, retain) IBOutlet UILabel *welcomeTitle;
@property (nonatomic, retain) IBOutlet CUIButton *closeWelcomePromptButton;
@property (nonatomic, retain) IBOutlet CUIButton *takePhotoButton;

@property (nonatomic, retain) IBOutlet UIView *translatePromptView;
@property (nonatomic, retain) IBOutlet UIView *translatePromptBubble;
@property (nonatomic, retain) IBOutlet UIView *sharePromptView;
@property (nonatomic, retain) IBOutlet UIView *sharePromptBubble;

@property (nonatomic, retain) UITableViewCell *selectedCell;

@property (nonatomic, readwrite) int matchNo;
@property (nonatomic, readwrite) bool showIntroPrompt;
@property (nonatomic, readwrite) bool chatDisabled;

// UI methods
- (void)setTimeForHeader;
- (void)setMissionsButton;
- (void)scrollToBottomWithAnimation:(bool)animated;
- (void)scrollToIndexPathWithAnimation:(NSIndexPath*)indexPath;
- (void)scrollToIndexPath:(NSIndexPath*)indexPath;
- (void)showWelcomeView;
- (void)enableChatButton;
- (void)disableChatButton;

// helper methods
- (CGFloat)getTextWidth:(NSString *)text;
- (CGFloat)getTextHeight:(NSString *)text;
- (void)reloadIndexPath:(NSIndexPath*)indexPath;
- (void)translateText:(NSIndexPath*)indexPath;
- (void)getChatData:(int)offsetMessageNo;
- (void)updateChatTable;
- (void)getMoreMessages;

// photo delivery helper methods
- (void)downloadThumbnail:(NSNumber*)messageNo withProgressView:(UIProgressView*)progressView;
- (void)sendPhoto:(ImageData*)imageDataObject withImageData:(NSData*)imageData withProgressView:(UIProgressView*)progressView;
- (void)sendPhotoToServer:(NSMutableDictionary*)requestData;
- (void)setThumbnailData:(NSDictionary*)thumbnailData;

// navigation methods
- (void)showMissionsAction;
- (void)showMissions:(bool)animated selectMission:(NSNumber*)missionNo;
- (void)goBack;
- (void)loadProfile;
- (void)didTouchThumbnailForObject:(NSManagedObjectID*)objectID showMap:(bool)showMap;
- (void)didTouchThumbnail:(id)sender;
- (void)didTouchLocation:(id)sender;
- (void)didTouchMission:(id)sender;
- (void)showShareViewController:(NSDictionary*)controllerData;
- (void)pushShareControllerWithData:(NSDictionary*)data;

// IBActions
- (IBAction)sendMessage;
- (IBAction)hideWelcomeView;
- (IBAction)attach;
- (IBAction)takeWelcomePhoto;
- (void)showOptions:(UIButton*)sender;
- (IBAction)dismissTranslationPrompt;
- (IBAction)dismissSharePrompt;
- (void)showMessageContextMenu:(NSTimer*)timer;

// queue pools
- (void)addToTextPool:(NSString*)key;
- (void)addObjectIDToUploadPool:(NSManagedObjectID*)objectID forKey:(NSString*)key;
- (void)addToResendPool:(NSString*)key;
- (void)addObjectIDToDownloadPool:(NSManagedObjectID*)objectID forKey:(NSString*)key;
- (void)addToRetryPool:(NSNumber*)retryCount forKey:(NSString*)key;
- (void)addToTranslationPool:(NSString*)key;
- (void)addToTranslatedMessages:(NSDictionary*)translatedMessage;
- (void)addToTwitterQueue:(NSString*)requestId forKey:(NSString*)key;
- (void)addToFacebookSharePool:(NSString*)key withData:(NSMutableDictionary*)shareData;
- (void)addToTwitterSharePool:(NSString*)key withData:(NSMutableDictionary*)shareData;

// twitter
- (void)newTweetForObjectID:(NSManagedObjectID*)objectID;
- (void)newTweetWithSender:(id)sender;
- (void)tweet:(NSMutableDictionary*)params;

// facebook
- (void)postFBFeedForObject:(NSManagedObjectID*)objectID;
- (void)postFBFeedWithSender:(id)sender;
- (void)postToFB:(NSMutableDictionary*)params;
- (void)handleFBLogin;
- (void)handleFBRequest:(NSDictionary<FBGraphUser>*)user;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

// table cells
- (UIView*)leftMessageCell:(int)sender;
- (UIView*)rightMessageCell;
- (UIView*)leftPhotoCell:(int)sender;
- (UIView*)rightPhotoCell;

@end
