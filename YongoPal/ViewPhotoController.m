//
//  ViewPhotoController.m
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

#import "ViewPhotoController.h"
#import "UtilityClasses.h"
#define ZOOM_VIEW_TAG 100

@implementation ViewPhotoController
@synthesize delegate;
@synthesize apiRequest;
@synthesize chatData;
@synthesize imageData;
@synthesize mapImage;
@synthesize imageView;
@synthesize key;
@synthesize matchData;
@synthesize imageScroll;
@synthesize downloadProgress;
@synthesize spinner;

@synthesize mapView;
@synthesize selectedAnnotationView;
@synthesize imageAnnotation;
@synthesize imageCalloutAnnotation;

@synthesize facebook;

@synthesize captionView;
@synthesize captionLabel;
@synthesize locationLabel;

@synthesize showMap;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        [self.navigationItem setCustomTitle:NSLocalizedString(@"viewPhotoTitle", nil)];
        
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:4];
        [operationQueue setSuspended:NO];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.mapView];

    [apiRequest setDelegate:nil];
    [apiRequest release];

    [operationQueue cancelAllOperations];
    [operationQueue release];
	[imageView release];
    [chatData release];
	[imageData release];
    [mapImage release];
	
	[twitter release];
    [facebook release];
    [key release];
    [matchData release];
    
	[imageScroll release];
	[downloadProgress release];
	[spinner release];
    
    [mapView release];
    [selectedAnnotationView release];
    [imageAnnotation release];
    [imageCalloutAnnotation release];
    
    [captionView release];
    [captionLabel release];
    [locationLabel release];

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

    self.apiRequest = [[[APIRequest alloc] init] autorelease];
    [self.apiRequest setDelegate:self];

	UIImage *backImage = [UIImage imageNamed:@"btn_back.png"];
	CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
	CUIButton *backButton = [[CUIButton alloc] initWithFrame:backFrame];
	[backButton setBackgroundImage:backImage forState:UIControlStateNormal];
	[backButton setShowsTouchWhenHighlighted:YES];
	[backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
	[self.navigationItem setLeftBarButtonItem:backBarButtonItem];
	[backBarButtonItem release];
	[backButton release];

	twitter = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
	twitter.consumerKey = twitterKey;
	twitter.consumerSecret = twitterSecret;
	
	[downloadProgress setHidden:YES];

	if(self.chatData != nil)
	{
        int sender = [[chatData valueForKey:@"sender"] intValue];
		self.imageData = [chatData valueForKey:@"imageData"];
		if(sender == [appDelegate.prefs integerForKey:@"memberNo"]) isOwner = YES;
		else isOwner = NO;
		if([[imageData valueForKey:@"messageNo"] intValue] == 0)
		{
			// get messageNo
			NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
			[requestData setValue:key forKey:@"keyNo"];
			NSDictionary *receivedChatData = [appDelegate.apiRequest sendServerRequest:@"chat" withTask:@"getMessageData" withData:requestData];
			[requestData release];

            if(receivedChatData)
            {
                messageNo = [[receivedChatData valueForKey:@"messageNo"] intValue];
                [imageData setValue:[NSNumber numberWithInt:messageNo] forKey:@"messageNo"];
            }
		}
		else
		{
			messageNo = [[imageData valueForKey:@"messageNo"] intValue];
		}
		[self loadImage:nil];
	}
	else
	{
		NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Data Error", @"title", @"Image data does not exist", @"message", nil];
		[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
		[alertContent release];
	}
	loadTweet = NO;
    
    NSString *cityName = [self.imageData valueForKey:@"cityName"];
    if(![cityName isEqualToString:@""] && cityName != nil)
    {
        NSString *locationName = [imageData valueForKey:@"locationName"];
        
        if(![locationName isEqualToString:@""] && locationName != nil)
        {
            [self.locationLabel setText:[NSString stringWithFormat:@"%@, %@", locationName, cityName]];
        }
        else
        {
            [self.locationLabel setText:[NSString stringWithFormat:@"near %@", cityName]];
        }
    }
    else
    {
        if(isOwner == YES)
        {
            [self.locationLabel setText:[NSString stringWithFormat:@"near %@", [appDelegate.prefs valueForKey:@"cityName"]]];
        }
        else
        {
            [self.locationLabel setText:[NSString stringWithFormat:@"near %@", [matchData valueForKey:@"cityName"]]];
        }
    }
    
    NSString *captionText = [self.imageData valueForKey:@"caption"];

    if(![captionText isEqualToString:@""] && captionText != nil)
	{
        [self.captionLabel setText:captionText];
        
        float originalHeight = self.captionLabel.frame.size.height;

		CGSize textSize = {self.captionLabel.frame.size.width, 99999.0f};		// width and height of text area
		CGSize size = [captionText sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:17.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];

        float newHeight = size.height - originalHeight;

        [self.captionView setFrame:CGRectMake(self.captionView.frame.origin.x, self.captionView.frame.origin.y - newHeight, captionView.frame.size.width, captionView.frame.size.height + newHeight)];

        [self.captionLabel setFrame:CGRectMake(self.captionLabel.frame.origin.x, self.captionLabel.frame.origin.y, size.width, size.height)];
	}
    else
    {
        [self.captionView setFrame:CGRectMake(self.captionView.frame.origin.x, self.captionView.frame.origin.y + self.captionLabel.frame.size.height, captionView.frame.size.width, captionView.frame.size.height - self.captionLabel.frame.size.height)];
        [self.captionLabel removeFromSuperview];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.mapView];
    
    [twitter release];
	twitter = nil;
    self.facebook = nil;

    [self.apiRequest setDelegate:nil];
    self.apiRequest = nil;
    self.imageData = nil;
    self.imageView = nil;
    self.imageScroll = nil;
	self.downloadProgress = nil;
	self.spinner = nil;

    self.mapView = nil;
    self.selectedAnnotationView = nil;
    self.imageAnnotation = nil;
    self.imageCalloutAnnotation = nil;
    
    self.captionView = nil;
    self.captionLabel = nil;
    self.locationLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    navBarIsHidden = NO;

    if(isOwner == YES)
    {
        [self setShareButton:NO];
        [appDelegate saveContext:appDelegate.mainMOC];
    }
    
    if([appDelegate.prefs boolForKey:@"hasSharedPhoto"] == NO)
    {
        [self setShareButton:YES];
    }
    else
    {
        [self setShareButton:NO];
    }

    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStateChanged:) name:YPSessionStateChangedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if(loadTweet == YES)
	{
		[self newTweet];
		loadTweet = NO;
	}
	else
	{
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"photoViewDidAppear"];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YPSessionStateChangedNotification object:nil];
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
    
    if(UIDeviceOrientationIsLandscape(currentOrientation))
    {
        // resize the navbar
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, [UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO], 32)];
        [[self.navigationController navigationBar] removeCaptions];
        
        return YES;
    }
    else if(UIDeviceOrientationIsPortrait(currentOrientation))
    {
        // resize the navbar
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, 320, 54)];
        [delegate setTimeForHeader];
        
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
    [imageScroll setContentSize:originalImageSize];

    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        imageRatio = [imageScroll frame].size.height  / originalImageSize.height;
        
    }
    else
    {
        imageRatio = [imageScroll frame].size.width  / originalImageSize.width;
        [delegate setTimeForHeader];
    }

	[imageScroll setMinimumZoomScale:imageRatio];
	[imageScroll setMaximumZoomScale:imageRatio + 2];
    
    if(originalImageSize.height > originalImageSize.width)
    {
        [imageScroll setZoomScale:([imageScroll frame].size.height  / originalImageSize.height)];
    }
    else
    {
        [imageScroll setZoomScale:imageRatio];
    }
}

- (void)setShareButton:(bool)active
{
    UIImage *shareImage = nil;
    if(active == YES)
    {
        shareImage = [UIImage imageNamed:@"btn_sharepink.png"];
    }
    else
    {
        shareImage = [UIImage imageNamed:@"btn_share.png"];
    }

	CGRect shareFrame = CGRectMake(0, 0, shareImage.size.width, shareImage.size.height);
	CUIButton *shareButton = [[CUIButton alloc] initWithFrame:shareFrame];
	[shareButton setBackgroundImage:shareImage forState:UIControlStateNormal];
	[shareButton setShowsTouchWhenHighlighted:YES];
	[shareButton addTarget:self action:@selector(sharePhoto) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *shareBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
	[self.navigationItem setRightBarButtonItem:shareBarButtonItem];
	[shareBarButtonItem release];
	[shareButton release];
}

-(CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center
{
	CGRect zoomRect;
    
    zoomRect.size.height = [imageScroll frame].size.height / scale;
    zoomRect.size.width  = [imageScroll frame].size.width  / scale;
    
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

- (void)selectAnnotation
{
    [self.mapView selectAnnotation:self.imageAnnotation animated:YES];
}

-(void)loadImage:(UIImage*)image
{
	[downloadProgress setProgress:0];
	[spinner setHidden:NO];

    if(image != nil || [imageData valueForKey:@"imageFile"] != nil)
    {
        if(image == nil)
        {
            NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:[imageData valueForKey:@"imageFile"]];
            image = [UIImage imageFromFile:imagePath];
            [downloadProgress setHidden:YES];
        }

        float latitude = [[self.imageData valueForKey:@"latitude"] floatValue];
        float longitude = [[self.imageData valueForKey:@"longitude"] floatValue];
        
        if(latitude == 0 && longitude == 0)
        {
            if(isOwner == YES)
            {
                latitude = [appDelegate.prefs floatForKey:@"latitude"];
                longitude = [appDelegate.prefs floatForKey:@"longitude"];
            }
            else
            {
                latitude = [[self.matchData valueForKey:@"latitude"] floatValue];
                longitude = [[self.matchData valueForKey:@"longitude"] floatValue];
            }
        }
        
        // setup map
        imageCoord = CLLocationCoordinate2DMake(latitude, longitude);
        
        [self.mapView setCenterCoordinate:imageCoord zoomLevel:5 animated:NO];
        
        self.mapImage = nil;
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
        {
            self.mapImage = [image resizedImageByScalingProportionally:CGSizeMake(150.0, 150.0)];
        }
        else
        {
            self.mapImage = [image resizedImageByScalingProportionally:CGSizeMake(75.0, 75.0)];
        }
        
        [self.mapView setHidden:NO];

        self.imageAnnotation = [[[BasicMapAnnotation alloc] initWithLatitude:imageCoord.latitude andLongitude:imageCoord.longitude] autorelease];
        
        if(self.showMap == YES)
        {
            [self performSelector:@selector(loadMap) withObject:nil];
        }

        [self performSelector:@selector(setImage:) withObject:image];
    }
	else
	{
		if(messageNo != 0)
		{
			[downloadProgress setHidden:NO];
			NSMutableDictionary *downloadRequestData = [[NSMutableDictionary alloc] init];
			[downloadRequestData setValue:[NSNumber numberWithInt:messageNo] forKey:@"messageNo"];
			[downloadRequestData setValue:key forKey:@"key"];
			[downloadRequestData setValue:[NSString stringWithFormat:@"%d", 0] forKey:@"width"];
			[downloadRequestData setValue:[NSString stringWithFormat:@"%d", 0] forKey:@"height"];
			[self.apiRequest getAsyncDataFromServer:@"chat" withTask:@"downloadPhoto" withData:downloadRequestData progressDelegate:downloadProgress];
			[downloadRequestData release];
		}
		else
		{
			NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Data Error", @"title", @"Message number for image does not exist", @"message", nil];
			[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
			[alertContent release];
		}
	}
}

-(void)setImage:(UIImage *)photoImage
{
    originalImageSize = photoImage.size;

	TapDetectingImageView *newTapView = [[TapDetectingImageView alloc] initWithImage:photoImage];
	[newTapView setDelegate:self];
	[newTapView setTag:ZOOM_VIEW_TAG];
	[imageScroll setContentSize:[newTapView frame].size];
	[imageScroll setImageView:newTapView];

    if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)
    {
        imageRatio = 320 / [newTapView frame].size.height;
    }
    else
    {
        imageRatio = [imageScroll frame].size.width / [newTapView frame].size.width;
    }

	[imageScroll setMinimumZoomScale:imageRatio];
	[imageScroll setMaximumZoomScale:imageRatio + 2];
    
    if([newTapView frame].size.height > [newTapView frame].size.width)
    {
        if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)
        {
            [imageScroll setZoomScale:(320 / [newTapView frame].size.height)];
        }
        else
        {
            [imageScroll setZoomScale:([imageScroll frame].size.height / [newTapView frame].size.height)];
        }
    }
    else
    {
        [imageScroll setZoomScale:imageRatio];
    }
	
	[spinner setHidden:YES];
	[downloadProgress setHidden:YES];
	
	self.imageView = newTapView;
    [newTapView release];
}

- (void)saveImage:(UIImage*)photoImage
{
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    ImageData *_imageData = (ImageData*)[threadContext objectWithID:[self.imageData objectID]];

    NSString *imageFile = [UtilityClasses saveImageData:UIImageJPEGRepresentation(photoImage, 1.0) named:@"image" withKey:key overwrite:YES];
    [_imageData setValue:imageFile forKey:@"imageFile"];    
	[appDelegate saveContext:threadContext];

    // run keep alive if current thread is not main thread
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:@selector(keepAlive:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
    }
}

- (IBAction)loadMap
{
    [self.mapView setHidden:NO];
    [self.mapView setCenterCoordinate:imageCoord zoomLevel:5 animated:NO];

    [UIView beginAnimations:@"showMap" context:nil];
    [UIView setAnimationDuration:0.25];
    [self.mapView setAlpha:1.0];
    [UIView commitAnimations];

	[self.mapView addAnnotation:imageAnnotation];
    [self.mapView selectAnnotation:imageAnnotation animated:YES];
}

- (void)hideMap
{    
    [UIView beginAnimations:@"hideMap" context:nil];
    [UIView setAnimationDuration:0.25];
    [self.mapView setAlpha:0.0];
    [UIView commitAnimations];
    
    [self.mapView performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.4];
}

- (void)keepAlive:(NSNumber *)fromBackground
{
    if(fromBackground)
    {
        [NSThread sleepForTimeInterval:0.1];
        [self performSelectorOnMainThread:@selector(keepAlive:) withObject:nil waitUntilDone:NO];
    }
}

- (void)goBack
{
    [self.mapView setDelegate:nil];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)sharePhoto
{
	UIActionSheet *sheet = nil;
	if(isOwner == NO)
	{
		sheet = [[UIActionSheet alloc]
								initWithTitle:nil
								delegate:self
								cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
								destructiveButtonTitle:nil
								otherButtonTitles:NSLocalizedString(@"facebookShareButton", nil), NSLocalizedString(@"twitterShareButton", nil), NSLocalizedString(@"saveToCameraRollButton", nil), nil];
	}
	else
	{
		sheet = [[UIActionSheet alloc]
								initWithTitle:nil
								delegate:self
								cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
								destructiveButtonTitle:nil
								otherButtonTitles:NSLocalizedString(@"facebookShareButton", nil), NSLocalizedString(@"twitterShareButton", nil), nil];
	}
	[sheet setTag:1];
	[sheet showInView:self.view];
	[sheet release];
}

- (void)postFBFeed
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

    NSString *firstName = nil;
    if(isOwner == YES)
    {
        firstName = [appDelegate.prefs valueForKey:@"firstName"];
    }
    else
    {
        firstName = [matchData valueForKey:@"firstName"];
    }
    
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

#pragma mark - tap zoom delegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView 
{
    return [imageScroll viewWithTag:ZOOM_VIEW_TAG];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint 
{
    if(navBarIsHidden == NO)
    {
        navBarIsHidden = YES;
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        
        [UIView beginAnimations:@"resizeScrollView" context:nil];
        [UIView setAnimationDuration:0.2];
        [imageScroll setFrame:self.view.frame];
        [captionView setFrame:CGRectMake(captionView.frame.origin.x, captionView.frame.origin.y + captionView.frame.size.height, captionView.frame.size.width, captionView.frame.size.height)];
        [UIView commitAnimations];
    }
    else
    {
        navBarIsHidden = NO;
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        
        // resize the navbar
        if([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)
        {
            CGRect navBarFrame = [[self.navigationController navigationBar] frame];
            CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, 32);
            [[self.navigationController navigationBar] resizeBGLayer:newFrame];
        }
        else
        {
            CGRect navBarFrame = [[self.navigationController navigationBar] frame];
            CGRect newFrame = CGRectMake(0, 0, navBarFrame.size.width, 54);
            [[self.navigationController navigationBar] resizeBGLayer:newFrame];
            [delegate setTimeForHeader];
        }

        [UIView beginAnimations:@"resizeScrollView" context:nil];
        [UIView setAnimationDuration:0.2];
        [imageScroll setFrame:CGRectMake(0, -44, imageScroll.frame.size.width, self.view.frame.size.height + 44)];
        [captionView setFrame:CGRectMake(captionView.frame.origin.x, captionView.frame.origin.y - captionView.frame.size.height, captionView.frame.size.width, captionView.frame.size.height)];
        [UIView commitAnimations];
    }
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint 
{
    // double tap zooms in
	if ([imageScroll zoomScale] < imageRatio + 2)
	{
		CGRect zoomRect = [self zoomRectForScale:[imageScroll zoomScale] * 2 withCenter:tapPoint];
		[imageScroll zoomToRect:zoomRect animated:YES];
	}
	else
	{
		CGRect zoomRect = [self zoomRectForScale:imageRatio withCenter:tapPoint];
		[imageScroll zoomToRect:zoomRect animated:YES];
	}
}

#pragma mark - actionSheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([appDelegate.prefs boolForKey:@"hasSharedPhoto"] == NO)
    {
        [self setShareButton:NO];
        [appDelegate.prefs setBool:YES forKey:@"hasSharedPhoto"];
        [appDelegate.prefs synchronize];
    }

	if(actionSheet.tag == 1)
	{
		// share on facebook
		if(buttonIndex == 0)
		{
            [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"touchFBFromPhotoView"];
			if(!FBSession.activeSession.isOpen)
			{
                [appDelegate openSessionWithAllowLoginUI:YES withPermissions:appDelegate.defaultPermissions];
			}
			else
			{
                [self postFBFeed];
			}
		}
		// share on twitter
		else if(buttonIndex == 1)
		{
            [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"touchTweetFromPhotoView"];

			if([twitter isAuthorized] == NO)
			{
				UIViewController *controller = [SA_OAuthTwitterController controllerToEnterCredentialsWithTwitterEngine:twitter delegate:self];
				[self presentModalViewController:controller animated: YES];
			}
			else
			{
				[self newTweet];
			}
		}
		// save to camera roll
		else if(buttonIndex == 2 && isOwner == NO)
		{
            NSInvocationOperation *saveImageOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveToCameraRoll) object:nil];
            [operationQueue addOperation:saveImageOperation];
            [saveImageOperation release];

            [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"savePhotoToAlbum"];
		}
	}
}

- (void)saveToCameraRoll
{
	NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:[imageData valueForKey:@"imageFile"]];
    UIImage *theImage = [UIImage imageFromFile:imagePath];
	UIImageWriteToSavedPhotosAlbum(theImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)newTweet
{
    NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:[imageData valueForKey:@"imageFile"]];
    UIImage *theImage = [UIImage imageFromFile:imagePath];
    UIImage *thumbnail = [theImage resizedImageByScalingProportionally:CGSizeMake(30.0, 30.0)];
    
	TweetViewController *tweetController = [[TweetViewController alloc] initWithNibName:@"TweetViewController" bundle:nil];
    [tweetController setLinkUrl:[imageData valueForKey:@"url"]];
    [tweetController setThumbnailImage:thumbnail];
    [tweetController setImageKey:[imageData valueForKey:@"key"]];
    [tweetController setIsOwner:isOwner];
	UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:tweetController];
	[[newNavController navigationBar] setBackgroundColor:[UIColor clearColor]];
	[self presentModalViewController:newNavController animated:YES];
	[tweetController release];
	[newNavController release];
}

#pragma mark - ASIHTTPReqeust delegate
- (void)didReceiveBinary:(NSData*)data andHeaders:(NSDictionary*)headers
{
    // if task was download photo get message number
    UIImage *downloadedImage = [UIImage imageWithData:data];

    [self loadImage:downloadedImage];
    
    NSInvocationOperation *saveImageOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveImage:) object:downloadedImage];
    [operationQueue addOperation:saveImageOperation];
    [saveImageOperation release];
    
    NSString *shortUrl = [headers objectForKey:@"X-Yongopal-Shorturl"];
    if(![shortUrl isEqualToString:[imageData valueForKey:@"url"]])
    {
        [imageData setValue:shortUrl forKey:@"url"];
        [appDelegate saveContext:appDelegate.mainMOC];
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
    
    [self postFBFeed];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldConfirmCrossPost" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[self.imageData valueForKey:@"key"], @"key", @"FB", @"postType", nil]];
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
	loadTweet = YES;
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
	[appDelegate hideLoading];
	[appDelegate didStopNetworking];
	[self dismissModalViewControllerAnimated:YES];
}

- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error
{
    [appDelegate hideLoading];
	[appDelegate didStopNetworking];
}

- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier
{

}

#pragma mark - save to camera roll delegate
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
	// Was there an error?
	if (error != NULL)
	{
		// Show error message...
		NSLog(@"error saving to camera roll: %@", error);
    }
}

#pragma mark - map view delegate
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	if (view.annotation == self.imageAnnotation)
	{
		if (self.imageCalloutAnnotation == nil)
		{
			self.imageCalloutAnnotation = [[[CalloutMapAnnotation alloc] initWithLatitude:view.annotation.coordinate.latitude andLongitude:view.annotation.coordinate.longitude] autorelease];
		}
		else
		{
			self.imageCalloutAnnotation.latitude = view.annotation.coordinate.latitude;
			self.imageCalloutAnnotation.longitude = view.annotation.coordinate.longitude;
		}
		
		self.selectedAnnotationView = view;
		[self.mapView addAnnotation:self.imageCalloutAnnotation];
	}
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
	// Remove the fake bubble annotation view on deselection.
	if (self.imageCalloutAnnotation && view.annotation == self.imageAnnotation)
    {
        [self.mapView removeAnnotation: self.imageCalloutAnnotation];
        [self hideMap];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView *annotationView = nil;
	
	if (annotation == self.imageCalloutAnnotation)
	{
		CVCustomCalloutAnnotationView *calloutMapAnnotationView = (CVCustomCalloutAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"ImageCalloutAnnotation"];
		
		if (!calloutMapAnnotationView)
		{
			calloutMapAnnotationView = [[[CVCustomCalloutAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ImageCalloutAnnotation"] autorelease];
            
            UIImageView *mapImageView = [[[UIImageView alloc] initWithImage:self.mapImage] autorelease];
            [mapImageView setFrame:CGRectMake(2, 2, 75.0, 75.0)];
            [mapImageView.layer setMasksToBounds:YES];
            [mapImageView.layer setCornerRadius:5];            
			[calloutMapAnnotationView.contentView addSubview:mapImageView];
		}
		
		calloutMapAnnotationView.parentAnnotationView = self.selectedAnnotationView;
		calloutMapAnnotationView.mapView = self.mapView;
		
		annotationView = calloutMapAnnotationView;
	}
	else if (annotation == self.imageAnnotation)
	{
		MKPinAnnotationView *pinAV = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ImageAnnotation"] autorelease];
		pinAV.canShowCallout = NO;
		pinAV.pinColor = MKPinAnnotationColorRed;
		annotationView = pinAV;
	}
	
	return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    [self performSelector:@selector(selectAnnotation) withObject:nil afterDelay:0.0];
}

@end
