//
//  SharePhotoController.h
//  Wander
//
//  Created by Jiho Kang on 9/17/11.
//  Copyright 2011 YongoPal, Inc. All rights reserved.
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
#import "YongoPalAppDelegate.h"
#import "MissionData.h"

// view controllers
#import "PreviewPhotoController.h"
#import "GeotagViewController.h"

// custom controllers
#import "HPGrowingTextView.h"
#import "CoreLocationController.h"

// core data
#import "MatchData.h"

// table cells
#import "ShareTableCell.h"
#import "PhotoPreviewCell.h"

// twitter
#import "SA_OAuthTwitterEngine.h"
#import "SA_OAuthTwitterController.h"

@protocol SharePhotoControllerDeleagte <NSObject>
- (void)resetNavControllerWithData:(NSDictionary*)data;
- (void)didHitBackFromShareView:(UIImagePickerControllerSourceType)sourceType;
- (void)queuePhoto:(UIImage*)image withKey:(NSString*)key andMetaData:(NSDictionary*)metaData saveToCameraRoll:(bool)save;
- (void)addToFacebookSharePool:(NSString*)key withData:(NSDictionary*)shareData;
- (void)addToTwitterSharePool:(NSString*)key withData:(NSDictionary*)shareData;
@end

@interface SharePhotoController : UIViewController
<
    UITableViewDataSource,
    UITableViewDelegate,
    PhotoPreviewCellDelegate,
    ShareTableCellDelegate,
    MGTwitterEngineDelegate,
    SA_OAuthTwitterEngineDelegate,
    SA_OAuthTwitterControllerDelegate,
    GeotagControllerDeleagte,
    CoreLocationControllerDelegate,
    HPGrowingTextViewDelegate
>
{
    YongoPalAppDelegate *appDelegate;
    HPGrowingTextView *captionTextView;
    SA_OAuthTwitterEngine *twitter;
    CoreLocationController *CLController;
    GeotagViewController *geotagController;
    id <SharePhotoControllerDeleagte> delegate;
    MatchData *matchData;
    UITableView *_tableView;
    NSMutableArray *listOfItems;
    UIImage *selectedImage;
    UIImage *thumbnail;
    
    NSString *locationName;
    NSString *locationId;
    
    NSNumber *missionNo;
    NSString *mission;
    
    UIImagePickerControllerSourceType sourceType;
    id selectedSwitch;
    bool shouldResetNavController;
    bool shouldSaveToCameraRoll;
    bool isGeoTagged;
    bool shareOnTwitter;
    bool shareOnFacebook;
    bool twitterIsAutherized;
    bool gpsIsWorking;
    float latitude;
    float longitude;
    int charCount;
    bool keyboardIsVisible;
    float originalTableHeight;
    
}

@property(nonatomic, assign) id <SharePhotoControllerDeleagte> delegate;
@property(nonatomic, retain) MatchData *matchData;
@property(nonatomic, retain) CoreLocationController *CLController;
@property(nonatomic, retain) GeotagViewController *geotagController;
@property(nonatomic, retain) HPGrowingTextView *captionTextView;
@property(nonatomic, retain) IBOutlet UITableView *_tableView;
@property(nonatomic, retain) NSMutableArray *listOfItems;
@property(nonatomic, retain) UIImage *selectedImage;
@property(nonatomic, retain) UIImage *thumbnail;
@property(nonatomic, retain) NSString *locationName;
@property(nonatomic, retain) NSString *locationId;
@property(nonatomic, retain) NSNumber *missionNo;
@property(nonatomic, retain) NSString *mission;
@property(nonatomic, readwrite) UIImagePickerControllerSourceType sourceType;
@property(nonatomic, readwrite) bool shouldResetNavController;
@property(nonatomic, readwrite) bool shouldSaveToCameraRoll;

- (void)goBack;
- (void)authTwitter;
- (void)didTouchDone;
- (void)sendPhoto;
- (CGFloat)getTextHeight:(NSString *)text;
- (NSString*)getShortURL:(NSString*)url;

- (void)handleFBLogin;
- (void)handleFBRequest:(NSDictionary<FBGraphUser>*)user;

@end
