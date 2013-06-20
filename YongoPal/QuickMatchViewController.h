//
//  QuickMatchViewController.h
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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
#import "YongoPalAppDelegate.h"
#import "MatchData.h"

#import "BasicMapAnnotation.h"
#import "CUIButton.h"
#import <OHAttributedLabel/OHAttributedLabel.h>
#import <OHAttributedLabel/NSAttributedString+Attributes.h>

#import "CalloutMapAnnotation.h"
#import "BasicMapAnnotation.h"

#import "MKMapView+ZoomLevel.h"

@interface QuickMatchViewController : UIViewController
{
    YongoPalAppDelegate *appDelegate;
    MatchData *matchData;
    MatchData *quickMatchData;
    NSArray *allLocations;
    NSMutableArray *annotationArray;
    
    MKMapView *mapView;
    CLLocationCoordinate2D currentCoord;
    
	MKAnnotationView *selectedAnnotationView;
	BasicMapAnnotation *userAnnotation;
	BasicMapAnnotation *partnerAnnotation;
    CalloutMapAnnotation *userCalloutAnnotation;
    CalloutMapAnnotation *partnerCalloutAnnotation;
    
	UIImageView *profileImage;
    
	UIView *buttonContainer;
    OHAttributedLabel *quickMatchLabel;
	UIView *resultView;
    UIView *selectYesPrompt;
    UIView *selectNoPrompt;
    
	CUIButton *confirmNoButton;
    CUIButton *confirmYesButton;
	NSOperationQueue *operationQueue;
	NSInvocationOperation *loadThumbnailOperation;
	UITextView *profileInfo;
    UIImageView *blankImageView;
    UIImageView *partnerImageView;
    
    int retryCount;
    int animationPass;
    bool shouldPushViewController;
}

@property (nonatomic, retain) MatchData *matchData;
@property (nonatomic, retain) MatchData *quickMatchData;

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) MKAnnotationView *selectedAnnotationView;
@property (nonatomic, retain) BasicMapAnnotation *userAnnotation;
@property (nonatomic, retain) BasicMapAnnotation *partnerAnnotation;
@property (nonatomic, retain) CalloutMapAnnotation *userCalloutAnnotation;
@property (nonatomic, retain) CalloutMapAnnotation *partnerCalloutAnnotation;

@property (nonatomic, retain) IBOutlet UIView *buttonContainer;
@property (nonatomic, retain) IBOutlet OHAttributedLabel *quickMatchLabel;
@property (nonatomic, retain) IBOutlet UIView *resultView;
@property (nonatomic, retain) IBOutlet UIView *selectYesPrompt;
@property (nonatomic, retain) IBOutlet UIView *selectNoPrompt;
@property (nonatomic, retain) IBOutlet CUIButton *confirmNoButton;
@property (nonatomic, retain) IBOutlet CUIButton *confirmYesButton;
@property (nonatomic, retain) IBOutlet UITextView *profileInfo;

@property (nonatomic, retain) UIImageView *blankImageView;
@property (nonatomic, retain) UIImageView *partnerImageView;
@property (nonatomic, retain) NSInvocationOperation *loadThumbnailOperation;

@property (nonatomic, readwrite) int matchNo;
@property (nonatomic, readwrite) int animationPass;
@property (nonatomic, readwrite) CLLocationCoordinate2D currentCoord;

- (void)zoomOut;
- (void)showConfirmMessage;
- (void)showDeclineMessage;
- (void)pushToIntroView;
- (void)setNavStack:(NSArray*)stack;
- (void)zoomIn;

- (IBAction)didConfirmQuickMatch;
- (IBAction)didDeclineQuickMatch;
- (IBAction)goBack;


@end
