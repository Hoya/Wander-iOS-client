//
//  MatchIntroViewController.h
//  YongoPal
//
//  Created by Jiho Kang on 9/2/11.
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
#import "UtilityClasses.h"
#import "MatchData.h"
#import "MKMapView+ZoomLevel.h"
#import "BasicMapAnnotation.h"
#import "CalloutMapAnnotation.h"
#import "CVCustomCalloutAnnotationView.h"

@interface MatchIntroViewController : UIViewController <MKMapViewDelegate>
{
    YongoPalAppDelegate *appDelegate;
    NSOperationQueue *operationQueue;

    MatchData *matchData;
    MKMapView *mapView;
    UIView *profileInfoContainer;
    UILabel *firstName;
    UILabel *location;
    UILabel *ageGender;
    UITextView *intro;
    UIView *buttonContainer;
    
    UIImageView *blankImageView;
    UIImageView *partnerImageView;
    
    MKAnnotationView *selectedAnnotationView;
    BasicMapAnnotation *partnerAnnotation;
    CalloutMapAnnotation *partnerCalloutAnnotation;
    
    NSTimer *timer;
    
    bool isModalView;
}

@property (nonatomic, retain) MatchData *matchData;
@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) IBOutlet UIView *profileInfoContainer;
@property (nonatomic, retain) IBOutlet UILabel *firstName;
@property (nonatomic, retain) IBOutlet UILabel *location;
@property (nonatomic, retain) IBOutlet UILabel *ageGender;
@property (nonatomic, retain) IBOutlet UITextView *intro;
@property (nonatomic, retain) IBOutlet UIView *buttonContainer;
@property (nonatomic, retain) UIImageView *blankImageView;
@property (nonatomic, retain) UIImageView *partnerImageView;
@property (nonatomic, retain) MKAnnotationView *selectedAnnotationView;
@property (nonatomic, retain) BasicMapAnnotation *partnerAnnotation;
@property (nonatomic, retain) CalloutMapAnnotation *partnerCalloutAnnotation;
@property (nonatomic, readwrite) bool isModalView;

- (void)setTimeForHeader;
- (void)goBack;
- (IBAction)getStarted;
- (void)transitionProfileImage;
- (void)goToChatScreen;
- (void)setNavStack:(NSArray*)stack;

@end
