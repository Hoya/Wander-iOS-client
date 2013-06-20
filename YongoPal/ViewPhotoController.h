//
//  ViewPhotoController.h
//  YongoPal
//
//  Created by Jiho Kang on 5/11/11.
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
#import <MapKit/MapKit.h>
#import "YongoPalAppDelegate.h"
#import "MKMapView+ZoomLevel.h"
#import "BasicMapAnnotation.h"
#import "CalloutMapAnnotation.h"
#import "CVCustomCalloutAnnotationView.h"
#import "SA_OAuthTwitterEngine.h"
#import "SA_OAuthTwitterController.h"
#import "TapDetectingImageView.h"
#import "MatchData.h"
#import "ChatData.h"
#import "ImageData.h"
#import "TweetViewController.h"

#import "ImageScrollView.h"

@protocol ViewPhotoControllerDeleagte <NSObject>
- (void)setTimeForHeader;
@end

@interface ViewPhotoController : UIViewController
<
    UIActionSheetDelegate,
    UIAlertViewDelegate,
    MKMapViewDelegate,
	TapDetectingImageViewDelegate,
    MGTwitterEngineDelegate,
	SA_OAuthTwitterEngineDelegate,
	SA_OAuthTwitterControllerDelegate,
    FBDialogDelegate,
    APIRequestDelegate
>
{
	YongoPalAppDelegate *appDelegate;
    id <ViewPhotoControllerDeleagte> delegate;
    APIRequest *apiRequest;
    NSOperationQueue *operationQueue;
	TapDetectingImageView *imageView;
    ChatData *chatData;
	ImageData *imageData;
    UIImage *mapImage;
	
	SA_OAuthTwitterEngine *twitter;
    Facebook *facebook;
    NSString *key;
    MatchData *matchData;

	ImageScrollView *imageScroll;
	UIProgressView *downloadProgress;
	UIActivityIndicatorView *spinner;
    
    MKAnnotationView *selectedAnnotationView;
    BasicMapAnnotation *imageAnnotation;
    CalloutMapAnnotation *imageCalloutAnnotation;
    
    UIView *captionView;
    UILabel *captionLabel;
    UILabel *locationLabel;

	double imageRatio;
	int messageNo;
	bool isOwner;
	bool loadTweet;
    bool navBarIsHidden;
    bool showMap;
    CLLocationCoordinate2D imageCoord;
    CGSize originalImageSize;
}

@property(nonatomic, assign) id <ViewPhotoControllerDeleagte> delegate;
@property(nonatomic, retain) APIRequest *apiRequest;
@property(nonatomic, retain) ChatData *chatData;
@property(nonatomic, retain) ImageData *imageData;
@property(nonatomic, retain) UIImage *mapImage;
@property(nonatomic, retain) TapDetectingImageView *imageView;
@property(nonatomic, retain) NSString *key;
@property(nonatomic, retain) MatchData *matchData;
@property(nonatomic, retain) IBOutlet ImageScrollView *imageScroll;
@property(nonatomic, retain) IBOutlet UIProgressView *downloadProgress;
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

@property(nonatomic, retain) IBOutlet MKMapView *mapView;
@property(nonatomic, retain) MKAnnotationView *selectedAnnotationView;
@property(nonatomic, retain) BasicMapAnnotation *imageAnnotation;
@property(nonatomic, retain) CalloutMapAnnotation *imageCalloutAnnotation;

@property (nonatomic, retain) Facebook *facebook;

@property(nonatomic, retain) IBOutlet UIView *captionView;
@property(nonatomic, retain) IBOutlet UILabel *captionLabel;
@property(nonatomic, retain) IBOutlet UILabel *locationLabel;

@property(nonatomic, readwrite) bool showMap;

- (void)setShareButton:(bool)active;
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;
- (void)selectAnnotation;
- (void)loadImage:(UIImage*)image;
- (void)setImage:(UIImage *)photoImage;
- (void)saveImage:(UIImage*)photoImage;
- (void)keepAlive:(NSNumber *)fromBackground;
- (IBAction)loadMap;
- (void)hideMap;
- (void)goBack;
- (void)sharePhoto;
- (void)postFBFeed;
- (void)saveToCameraRoll;
- (void)newTweet;
- (void)handleFBLogin;
- (void)handleFBRequest:(NSDictionary<FBGraphUser>*)user;

@end
