//
//  NewMatchViewController.h
//  YongoPal
//
//  Created by Jiho Kang on 4/13/11.
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
#import <MapKit/MapKit.h>
#import "YongoPalAppDelegate.h"
#import "MatchData.h"
#import "CUIButton.h"
#import <OHAttributedLabel/OHAttributedLabel.h>
#import <OHAttributedLabel/NSAttributedString+Attributes.h>

#import "CalloutMapAnnotation.h"
#import "CVCustomCalloutAnnotationView.h"
#import "BasicMapAnnotation.h"

#import "MKMapView+ZoomLevel.h"

@interface NewMatchViewController : UIViewController
<
    MKMapViewDelegate,
    APIRequestDelegate
>
{
	YongoPalAppDelegate *appDelegate;
    APIRequest *apiRequest;
	MatchData *matchData;

    MKMapView *mapView;
    CLLocationCoordinate2D currentCoord;

	MKAnnotationView *userAnnotationView;
    MKAnnotationView *partnerAnnotationView;
	BasicMapAnnotation *userAnnotation;
	BasicMapAnnotation *partnerAnnotation;
    CalloutMapAnnotation *userCalloutAnnotation;
    CalloutMapAnnotation *partnerCalloutAnnotation;
    UIView *mapCover;
    
	UIImageView *profileImage;

	UIView *buttonContainer;
	UIView *resultView;
	UIView *selectYes;
	UIView *selectNo;
	CUIButton *confirmButton;
	CUIButton *confirmButton2;
	OHAttributedLabel *confirmMessage;
	NSOperationQueue *operationQueue;
	NSInvocationOperation *loadThumbnailOperation;
	UITextView *profileInfo;
    UIImageView *blankImageView;
    UIImageView *partnerImageView;
    
    UIView *confirmDeclineView;
    CUIButton *cancelDeclineButton;
    CUIButton *confirmDeclineButton;
    
    OHAttributedLabel *welcomeTextLabel;
    
    NSTimer *timer;
    int matchNo;
    int animationPass;
    bool shouldPlayMapAnimation;
}

@property (nonatomic, retain) APIRequest *apiRequest;
@property (nonatomic, retain) MatchData *matchData;
@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) IBOutlet UIView *mapCover;
@property (nonatomic, retain) MKAnnotationView *userAnnotationView;
@property (nonatomic, retain) MKAnnotationView *partnerAnnotationView;
@property (nonatomic, retain) BasicMapAnnotation *userAnnotation;
@property (nonatomic, retain) BasicMapAnnotation *partnerAnnotation;
@property (nonatomic, retain) CalloutMapAnnotation *userCalloutAnnotation;
@property (nonatomic, retain) CalloutMapAnnotation *partnerCalloutAnnotation;

@property (nonatomic, retain) IBOutlet UIView *buttonContainer;
@property (nonatomic, retain) IBOutlet UIView *resultView;
@property (nonatomic, retain) IBOutlet UIView *selectYes;
@property (nonatomic, retain) IBOutlet UIView *selectNo;
@property (nonatomic, retain) IBOutlet CUIButton *confirmButton;
@property (nonatomic, retain) IBOutlet CUIButton *confirmButton2;
@property (nonatomic, retain) IBOutlet OHAttributedLabel *confirmMessage;
@property (nonatomic, retain) IBOutlet UITextView *profileInfo;
@property (nonatomic, retain) UIImageView *blankImageView;
@property (nonatomic, retain) UIImageView *partnerImageView;
@property (nonatomic, retain) NSInvocationOperation *loadThumbnailOperation;

@property (nonatomic, retain) IBOutlet UIView *confirmDeclineView;
@property (nonatomic, retain) IBOutlet UIView *confirmDeclineDialog;
@property (nonatomic, retain) IBOutlet CUIButton *cancelDeclineButton;
@property (nonatomic, retain) IBOutlet CUIButton *confirmDeclineButton;
@property (nonatomic, retain) IBOutlet OHAttributedLabel *welcomeTextLabel;

@property (nonatomic, readwrite) int matchNo;
@property (nonatomic, readwrite) int animationPass;
@property (nonatomic, readwrite) CLLocationCoordinate2D currentCoord;


@property (nonatomic, retain) CalloutMapAnnotation *calloutAnnotation;
@property (nonatomic, retain) BasicMapAnnotation *customAnnotation;
@property (nonatomic, retain) BasicMapAnnotation *normalAnnotation;



- (void)setLocations;
- (void)setPartnerLocation;
- (void)showPartnerLocation;
- (void)zoomMap:(NSNumber*)zoomLevel;
- (void)transitionProfileImage;
- (void)setTimeForHeader;
- (IBAction)didTouchYes;
- (void)confirmMatch;
- (void)processResults:(NSDictionary*)apiResult;
- (void)showConfirmMessage;
- (void)showDeclineMessage;
- (IBAction)didTouchNo;
- (IBAction)cancelDecline;
- (IBAction)confirmDecline;
- (void)hideConfirmDeclineDialog;
- (void)declineMatch;
- (IBAction)cancelMatch;

@end
