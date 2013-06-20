//
//  SharePhotoController.m
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

#import "SharePhotoController.h"
#import "UtilityClasses.h"

@implementation SharePhotoController
@synthesize delegate;
@synthesize matchData;
@synthesize CLController;
@synthesize geotagController;
@synthesize captionTextView;
@synthesize _tableView;
@synthesize listOfItems;
@synthesize selectedImage;
@synthesize thumbnail;
@synthesize locationName;
@synthesize locationId;
@synthesize missionNo;
@synthesize mission;
@synthesize sourceType;
@synthesize shouldResetNavController;
@synthesize shouldSaveToCameraRoll;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        twitter = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
        twitter.consumerKey = twitterKey;
        twitter.consumerSecret = twitterSecret;
        twitterIsAutherized = [twitter isAuthorized];
        
        // set keyboard notifications
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [dnc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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

    _tableView.backgroundColor = [UIColor clearColor];
    
    //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController setNavigationBarHidden:NO];

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

    UIImage *doneImage = [UIImage imageNamed:@"btn_done.png"];
	CGRect doneFrame = CGRectMake(0, 0, doneImage.size.width, doneImage.size.height);
	CUIButton *doneButton = [[CUIButton alloc] initWithFrame:doneFrame];
	[doneButton setBackgroundImage:doneImage forState:UIControlStateNormal];
	[doneButton setShowsTouchWhenHighlighted:YES];
	[doneButton addTarget:self action:@selector(didTouchDone) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
	[self.navigationItem setRightBarButtonItem:doneBarButtonItem];
	[doneBarButtonItem release];
	[doneButton release];
    
    self.listOfItems = [[[NSMutableArray alloc] init] autorelease];

    isGeoTagged = [appDelegate.prefs boolForKey:@"defaultGeotagging"];

    NSMutableArray *group0;
    
    if(isGeoTagged == YES)
    {
        self.CLController = nil;
        self.CLController = [[[CoreLocationController alloc] init] autorelease];
        [self.CLController setDelegate:self];
        [self.CLController.locationManager startUpdatingLocation];

        if(self.mission != nil)
        {
            group0 = [[NSMutableArray alloc] initWithObjects:@"Caption", self.mission, @"Location", @"", nil];
        }
        else
        {
            group0 = [[NSMutableArray alloc] initWithObjects:@"Caption", @"Location", @"", nil];
        }
    }
    else
    {
        if(self.mission != nil)
        {
            group0 = [[NSMutableArray alloc] initWithObjects:@"Caption", self.mission, @"Location", nil];
        }
        else
        {
            group0 = [[NSMutableArray alloc] initWithObjects:@"Caption", @"Location", nil];
        }
    }

	NSMutableDictionary *group0Dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:group0, @"photoInfo", nil];
	[group0 release];
	[listOfItems addObject:group0Dict];
	[group0Dict release];

    NSMutableArray *group1 = [[NSMutableArray alloc] initWithObjects:@"Facebook", @"Twitter", nil];
    NSMutableDictionary *group1Dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:group1, @"photoInfo", nil];
    [group1 release];
    [listOfItems addObject:group1Dict];
    [group1Dict release];

    self.captionTextView = [[[HPGrowingTextView alloc] initWithFrame:CGRectMake(0, 0, 192, 80)] autorelease];
    [self.captionTextView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self.captionTextView setClipsToBounds:YES];
    [self.captionTextView.layer setMasksToBounds:YES];
    [self.captionTextView setMinNumberOfLines:3];
    [self.captionTextView setMaxNumberOfLines:3];
    [self.captionTextView setReturnKeyType:UIReturnKeyDefault];
    [self.captionTextView.internalTextView setBackgroundColor:[UIColor clearColor]];
    [self.captionTextView setText:@""];
    [self.captionTextView setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:17.0f]];
    [self.captionTextView setDelegate:self];
    [self.captionTextView setReturnKeyType:UIReturnKeyDone];

    UILabel *placeholder = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 150, 25)];
    [placeholder setText:@"Add a caption"];
    [placeholder setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:17.0f]];
    [placeholder setTextColor:UIColorFromRGB(0xCCCCCC)];
    [placeholder setTag:1];
    [self.captionTextView insertSubview:placeholder belowSubview:[[self.captionTextView subviews] objectAtIndex:0]];
    [placeholder release];
    
    [[NSNotificationCenter defaultCenter] addObserver:self._tableView selector:@selector(reloadData) name: UIApplicationDidBecomeActiveNotification object:nil];
    
    self.geotagController = [[[GeotagViewController alloc] initWithNibName:@"GeotagViewController" bundle:nil] autorelease];
    [self.geotagController setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    if(shouldResetNavController == YES)
    {
        CGRect tableFrame = self._tableView.frame;
        [self._tableView setFrame:CGRectMake(tableFrame.origin.x, 44, tableFrame.size.width, tableFrame.size.height)];
    }
    else
    {
        CGRect tableFrame = self._tableView.frame;
        [self._tableView setFrame:CGRectMake(tableFrame.origin.x, 0, tableFrame.size.width, tableFrame.size.height)];
    }
    
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStateChanged:) name:YPSessionStateChangedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(shouldResetNavController == YES)
    {
        NSDictionary *delegateData = [NSDictionary dictionaryWithObjectsAndKeys:
                                      self.selectedImage, @"image", 
                                      self.thumbnail, @"thumbnail", 
                                      [NSNumber numberWithBool:shouldSaveToCameraRoll], @"shouldSaveToCameraRoll", 
                                      [NSNumber numberWithInt:sourceType], @"sourceType", 
                                      nil];
        [delegate resetNavControllerWithData:delegateData];
    }
    [self._tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YPSessionStateChangedNotification object:nil];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self._tableView];

    [super viewDidUnload];

    self.listOfItems = nil;
    self.geotagController = nil;
    self._tableView = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [matchData release];
    [listOfItems release];
    [geotagController release];
    [twitter release];
    [captionTextView release];
    [_tableView release];
    [selectedImage release];
    [thumbnail release];
    [locationName release];
    [locationId release];
    [missionNo release];
    [mission release];
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
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, 320, 44)];
        
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

- (void)goBack
{
    [delegate didHitBackFromShareView:sourceType];
}

- (void)authTwitter
{
    UIViewController *controller = [SA_OAuthTwitterController controllerToEnterCredentialsWithTwitterEngine:twitter delegate:self];
    [self presentModalViewController:controller animated:YES];
    [appDelegate hideLoading];
}

- (void)didTouchDone
{
    [appDelegate showLoading];
    [self.captionTextView resignFirstResponder];
    [self performSelectorOnMainThread:@selector(sendPhoto) withObject:nil waitUntilDone:NO];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        if(self.missionNo == nil)
        {
            if(self.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
            {
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"choosePhotoFromChatView"];
            }
            else
            {
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"takePhotoFromChatView"];
            }
        }
        else
        {
            if(self.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
            {
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"choosePhotoFromMissionView"];
            }
            else
            {
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"takePhotoFromMissionView"];
            }
        }
    }
}

- (void)sendPhoto
{
    if([appDelegate.networkStatus boolValue] == NO)
    {
        return;
    }

    NSString *key = [UtilityClasses generateKey];
    NSString *keyBase64 = [NSString base64StringFromData:[key dataUsingEncoding:NSUTF8StringEncoding] length:[[key dataUsingEncoding:NSUTF8StringEncoding] length]];
    keyBase64 = [keyBase64 stringByReplacingOccurrencesOfString:@"=" withString:@""];

    NSMutableDictionary *metaData = [[NSMutableDictionary alloc] init];
    if(![self.captionTextView.text isEqualToString:@""])
    {
        [metaData setValue:self.captionTextView.text forKey:@"caption"];
    }

    if(self.missionNo != nil && self.mission != nil)
    {
        [metaData setValue:self.missionNo forKey:@"missionNo"];
        [metaData setValue:self.mission forKey:@"mission"];
    }

    NSString *caption = nil;
    if([self.captionTextView.text isEqualToString:@""])
    {
        caption = [NSString stringWithFormat:@"I'm using Wander to explore %@ with %@ as a local guide!", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"firstName"]];
    }
    else
    {
        caption = self.captionTextView.text;
    }
    
    if(isGeoTagged == YES)
    {
        [metaData setValue:[NSNumber numberWithFloat:latitude] forKey:@"latitude"];
        [metaData setValue:[NSNumber numberWithFloat:longitude] forKey:@"longitude"];

        NSDictionary *geocodeData = [UtilityClasses reverseGeocode:latitude longitude:longitude sensorOn:YES];
        if(geocodeData)
        {
            [metaData setValue:[geocodeData valueForKey:@"cityName"] forKey:@"cityName"];
            if([geocodeData valueForKey:@"provinceName"])
            {
                [metaData setValue:[geocodeData valueForKey:@"provinceName"] forKey:@"provinceName"];
                
                if([geocodeData valueForKey:@"provinceCode"])
                {
                    [metaData setValue:[geocodeData valueForKey:@"provinceCode"] forKey:@"provinceCode"];
                }
            }
            [metaData setValue:[geocodeData valueForKey:@"countryName"] forKey:@"countryName"];
            [metaData setValue:[geocodeData valueForKey:@"countryCode"] forKey:@"countryCode"];

            if(self.locationName != nil)
            {
                [metaData setValue:self.locationName forKey:@"locationName"];
            }

            if(self.locationId != nil)
            {
                [metaData setValue:self.locationId forKey:@"locationId"];
            }
        }
    }

    if(shareOnTwitter || shareOnFacebook)
    {
        NSString *longURL = [NSString stringWithFormat:@"http://%@/viewPhoto/index/%@", appDelegate.apiHost, keyBase64];
        NSString *shortUrl = [self getShortURL:longURL];

        if(shareOnTwitter == YES)
        {
            NSMutableDictionary *twitterParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:caption, @"caption", shortUrl, @"url", nil];
            [delegate addToTwitterSharePool:key withData:twitterParams];
        }

        if(shareOnFacebook == YES && shortUrl != nil)
        {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

            [params setObject:self.captionTextView.text forKey:@"message"];
            [params setObject:[NSString stringWithFormat:@"%@'s photo on Wander", [appDelegate.prefs valueForKey:@"firstName"]] forKey:@"name"];
            [params setObject:shortUrl forKey:@"link"];

            NSString *imageURL = [NSString stringWithFormat:@"http://%@/viewPhoto/downloadImage/%@", appDelegate.apiHost, key];

            [params setObject:imageURL forKey:@"picture"];
            [params setObject:@"photo" forKey:@"type"];
            [params setObject:[NSString stringWithFormat:@"%@, %@", [appDelegate.prefs valueForKey:@"cityName"], [appDelegate.prefs valueForKey:@"countryName"]] forKey:@"caption"];
            [params setObject:[NSString stringWithFormat:@"I'm using Wander to explore %@ with %@ as a local guide!", [matchData valueForKey:@"cityName"], [matchData valueForKey:@"firstName"]] forKey:@"description"];

            [delegate addToFacebookSharePool:key withData:params];
            
            [params release];
        }
    }

    [delegate queuePhoto:self.selectedImage withKey:key andMetaData:metaData saveToCameraRoll:shouldSaveToCameraRoll];
    [metaData release];
}

- (NSString*)getShortURL:(NSString*)url
{
    if(appDelegate.networkStatus == NO)
	{
		return nil;
	}

#warning this needs to be filled in
    NSURL *bitlyURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=some_id&apiKey=%@&domain=wndrw.me&longUrl=%@", bitlyKey, url]];

    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:bitlyURL];
    [request setAllowCompressedResponse:YES];
    [request setShouldWaitToInflateCompressedResponses:NO];
    [request setNumberOfTimesToRetryOnTimeout:2];
    [request setShouldAttemptPersistentConnection:NO];
    [request startSynchronous];
    [appDelegate didStopNetworking];
    
    NSError *error = [request error];
    
    NSString *shortURL = nil;
    if (!error)
    {
        SBJsonParser *jsonParser = [[SBJsonParser alloc] init];

        NSString *json_string = [request responseString];
        NSDictionary *apiResult = [jsonParser objectWithString:json_string error:nil];
        shortURL = [[apiResult valueForKey:@"data"] valueForKey:@"url"];
        [jsonParser release];
    }
    [request release];
    
    return shortURL;
}

- (CGFloat)getTextHeight:(NSString *)text
{
	CGFloat result = 0;
    
	if (text)
	{
		CGSize textSize = {210.0f, 99999.0f};		// width and height of text area
		CGSize size = [text sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
        
		result = size.height;
	}
    
	return result;
}

#pragma mark - table view data source and table delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [listOfItems count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSDictionary *dictionary = [listOfItems objectAtIndex:section];
	NSArray *array = [dictionary objectForKey:@"photoInfo"];
	return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *PhotoCellIdentifier = @"PhotoCell";
    static NSString *LocationCellIdentifier = @"LocationCell";
    static NSString *ShareCellIdentifier = @"ShareCell";
    static NSString *CellIdentifier = nil;

    if(indexPath.section == 0 && indexPath.row == 0)
    {
        CellIdentifier = PhotoCellIdentifier;
        PhotoPreviewCell *cell = (PhotoPreviewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            NSArray *aCell = [[NSBundle mainBundle] loadNibNamed:@"PhotoPreviewCell" owner:nil options:nil];
            cell = [aCell objectAtIndex:0];
            [cell setDelegate:self];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

            [cell.thumbnailView.layer setMasksToBounds:YES];
            [cell.thumbnailView.layer setCornerRadius:5.0];

            [cell.thumbnailView setImage:self.thumbnail];
            [cell.captionContainer setAutoresizesSubviews:YES];
            [self.captionTextView setFrame:CGRectMake(0, 0, cell.captionContainer.frame.size.width, cell.captionContainer.frame.size.height)];
            [cell.captionContainer addSubview:self.captionTextView];
        }

        return cell;
    }
    else
    {
        if(self.missionNo == nil && indexPath.section == 0 && indexPath.row == 2)
        {
            CellIdentifier = LocationCellIdentifier;
        }
        else if(self.missionNo != nil && indexPath.section == 0 && indexPath.row == 3)
        {
            CellIdentifier = LocationCellIdentifier;
        }
        else
        {
            CellIdentifier = ShareCellIdentifier;
        }

        ShareTableCell *cell = (ShareTableCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            NSArray *aCell = [[NSBundle mainBundle] loadNibNamed:@"ShareTableCell" owner:nil options:nil];
            
            if(self.missionNo == nil && indexPath.section == 0 && indexPath.row == 2)
            {
                cell = [aCell objectAtIndex:1];
            }
            else if(self.missionNo != nil && indexPath.section == 0 && indexPath.row == 3)
            {
                cell = [aCell objectAtIndex:1];
            }
            else
            {
                cell = [aCell objectAtIndex:0];
            }

            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cell setDelegate:self];
            
            NSDictionary *dictionary = [listOfItems objectAtIndex:indexPath.section];
            NSArray *array = [dictionary objectForKey:@"photoInfo"];
            [cell.shareLabel setText:[array objectAtIndex:indexPath.row]];

            if(indexPath.section == 0)
            {
                if(indexPath.row == 1 && self.missionNo != nil)
                {
                    [cell.configureLabel setHidden:YES];
                    [cell.arrowImage setHidden:YES];
                    [cell.shareSwitch setHidden:YES];
                    [cell.iconImage setImage:[UIImage imageNamed:@"ico_addmission"]];
                    [cell.shareLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0f]];
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                }
                else if((indexPath.row == 1 && self.missionNo == nil) || (indexPath.row == 2 && self.missionNo != nil))
                {
                    [cell.shareSwitch setTag:1];
                    [cell.shareSwitch setOn:isGeoTagged];
                    [cell.iconImage setImage:[UIImage imageNamed:@"ico_geo"]];
                    [cell.configureLabel setHidden:YES];
                    [cell.arrowImage setHidden:YES];
                    [cell.shareSwitch setHidden:NO];
                    
                    if(gpsIsWorking == YES)
                    {
                        [cell.shareSwitch setHidden:YES];
                        [cell.spinner startAnimating];
                    }
                    else
                    {
                        [cell.shareSwitch setHidden:NO];
                        [cell.spinner stopAnimating];
                    }
                }
                if((indexPath.row == 2 && self.missionNo == nil) || (indexPath.row == 3 && self.missionNo != nil))
                {
                    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
                    [cell.configureLabel setText:@"Add a place"];
                    
                    if([cell.shareLabel.text isEqualToString:@""])
                    {
                        [cell.configureLabel setHidden:NO];
                        [cell.arrowImage setHidden:NO];
                    }
                    else
                    {
                        [cell.configureLabel setHidden:YES];
                        [cell.arrowImage setHidden:YES];
                    }
                }
            }
            else if(indexPath.section == 1)
            {
                if(indexPath.row == 0)
                {
                    [cell.shareSwitch setTag:2];
                    [cell.shareSwitch setOn:shareOnFacebook];
                    [cell.iconImage setImage:[UIImage imageNamed:@"ico_fb"]];

                    if(FBSession.activeSession.isOpen && [FBSession.activeSession.permissions containsObject:@"publish_stream"])
                    {
                        [cell.configureLabel setHidden:YES];
                        [cell.arrowImage setHidden:YES];
                        [cell.shareSwitch setHidden:NO];
                        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    }
                    else
                    {
                        [cell.configureLabel setHidden:NO];
                        [cell.arrowImage setHidden:NO];
                        [cell.shareSwitch setHidden:YES];
                        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
                    }
                }
                else if(indexPath.row == 1)
                {
                    [cell.shareSwitch setTag:3];
                    [cell.shareSwitch setOn:shareOnTwitter];
                    [cell.iconImage setImage:[UIImage imageNamed:@"ico_tw"]];
                    
                    if(twitterIsAutherized == NO)
                    {
                        [cell.configureLabel setHidden:NO];
                        [cell.arrowImage setHidden:NO];
                        [cell.shareSwitch setHidden:YES];
                        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
                    }
                    else
                    {
                        [cell.configureLabel setHidden:YES];
                        [cell.arrowImage setHidden:YES];
                        [cell.shareSwitch setHidden:NO];
                        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    }
                }
            }
        }

        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0 && indexPath.row == 0)
    {
        return 100.0;
    }
    else
    {
        NSDictionary *dictionary = [listOfItems objectAtIndex:indexPath.section];
        NSArray *array = [dictionary objectForKey:@"photoInfo"];
        NSString *label = [array objectAtIndex:indexPath.row];
        
        float textHeight = [self getTextHeight:label];
        
        if(textHeight > 44)
        {
            return textHeight + 10;
        }
        else
        {
            return 44.0;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.captionTextView resignFirstResponder];
    if(indexPath.section == 0)
    {
        if(self.missionNo != nil && indexPath.row == 1)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        else if((self.missionNo == nil && indexPath.row == 2) || (self.missionNo != nil && indexPath.row == 3))
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self.navigationController pushViewController:self.geotagController animated:YES];
        }
    }
    else if(indexPath.section == 1)
    {
        ShareTableCell *cell = (ShareTableCell*)[tableView cellForRowAtIndexPath:indexPath];
        [cell.shareSwitch setOn:YES];
        id shareSwitch = cell.shareSwitch;
        [self didTouchSwitch:shareSwitch];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;
	switch (section)
	{
            /*
		case 0:
			title = @"About this Photo";
			break;
             */
		case 1:
			title = @"Share with Friends!";
			break;
		default:
			break;
	}
	return title;
}

#pragma mark - table view delegate
- (void)previewPhoto
{
    PreviewPhotoController *previewController = [[PreviewPhotoController alloc] initWithNibName:@"PreviewPhotoController" bundle:nil];
    previewController.receivedPhoto = selectedImage;
    [self.navigationController pushViewController:previewController animated:YES];
    [previewController release];
}

- (void)didTouchSwitch:(id)sender
{
    [self.captionTextView resignFirstResponder];

    selectedSwitch = sender;
    UISwitch *shareSwitch = sender;

    switch (shareSwitch.tag)
    {
        case 1:
            if(shareSwitch.isOn == YES)
            {
                gpsIsWorking = YES;

                if(self.missionNo == nil)
                {
                    NSIndexPath *reloadPath = [NSIndexPath indexPathForRow:1 inSection:0];
                    [self._tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:reloadPath, nil] withRowAnimation:UITableViewRowAnimationNone];
                }
                else
                {
                    NSIndexPath *reloadPath = [NSIndexPath indexPathForRow:2 inSection:0];
                    [self._tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:reloadPath, nil] withRowAnimation:UITableViewRowAnimationNone];
                }
                
                self.CLController = nil;
                self.CLController = [[[CoreLocationController alloc] init] autorelease];
                [self.CLController setDelegate:self];
                [self.CLController.locationManager startUpdatingLocation];
                
                NSMutableDictionary *group0Dict = [listOfItems objectAtIndex:0];
                NSMutableArray *group0 = [group0Dict valueForKey:@"photoInfo"];
                [group0 addObject:@""];
                
                if(self.missionNo == nil)
                {
                    NSIndexPath *newPath = [NSIndexPath indexPathForRow:2 inSection:0];
                    [self._tableView beginUpdates];
                    [self._tableView insertRowsAtIndexPaths:[NSArray arrayWithObjects:newPath, nil] withRowAnimation:UITableViewRowAnimationTop];
                    [self._tableView endUpdates];
                }
                else
                {
                    NSIndexPath *newPath = [NSIndexPath indexPathForRow:3 inSection:0];
                    [self._tableView beginUpdates];
                    [self._tableView insertRowsAtIndexPaths:[NSArray arrayWithObjects:newPath, nil] withRowAnimation:UITableViewRowAnimationTop];
                    [self._tableView endUpdates];
                }

                isGeoTagged = YES;
                [appDelegate.prefs setBool:YES forKey:@"defaultGeotagging"];
                [appDelegate.prefs synchronize];
            }
            else
            {
                NSMutableDictionary *group0Dict = [listOfItems objectAtIndex:0];
                NSMutableArray *group0 = [group0Dict valueForKey:@"photoInfo"];

                if(self.missionNo == nil)
                {
                    if([group0 count] == 3)
                    {
                        [group0 removeObjectAtIndex:2];
                    }
                    
                    NSIndexPath *deletePath = [NSIndexPath indexPathForRow:2 inSection:0];
                    
                    [self._tableView beginUpdates];
                    [self._tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:deletePath, nil] withRowAnimation:UITableViewRowAnimationTop];
                    [self._tableView endUpdates];
                }
                else
                {
                    if([group0 count] == 4)
                    {
                        [group0 removeObjectAtIndex:3];
                    }
                    
                    NSIndexPath *deletePath = [NSIndexPath indexPathForRow:3 inSection:0];
                    
                    [self._tableView beginUpdates];
                    [self._tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:deletePath, nil] withRowAnimation:UITableViewRowAnimationTop];
                    [self._tableView endUpdates];
                }

                isGeoTagged = NO;
                [appDelegate.prefs setBool:NO forKey:@"defaultGeotagging"];
                [appDelegate.prefs synchronize];
            }
            break;
        case 2:
            if(shareSwitch.isOn == YES)
            {
                if(!FBSession.activeSession.isOpen)
                {
                    shareOnFacebook = NO;
                    NSMutableArray *permissions = [NSMutableArray arrayWithArray:appDelegate.defaultPermissions];
                    [permissions addObject:@"publish_stream"];
                    [appDelegate openSessionWithAllowLoginUI:YES withPermissions:permissions];
                }
                else
                {
                    if(![FBSession.activeSession.permissions containsObject:@"publish_stream"])
                    {
                        shareOnFacebook = NO;
                        [FBSession.activeSession close];
                        NSMutableArray *permissions = [NSMutableArray arrayWithArray:appDelegate.defaultPermissions];
                        [permissions addObject:@"publish_stream"];
                        [appDelegate openSessionWithAllowLoginUI:YES withPermissions:permissions];
                    }
                    else
                    {
                        shareOnFacebook = YES;
                    }
                }
            }
            else
            {
                shareOnFacebook = NO;
            }
            break;
        case 3:
            if(shareSwitch.isOn == YES)
            {                
                // show twitter auth view if user is not signed in
                if(twitterIsAutherized == NO)
                {
                    shareOnTwitter = NO;
                    [appDelegate showLoading];
                    [self performSelector:@selector(authTwitter) withObject:nil afterDelay:0.0];
                }
                else
                {
                    shareOnTwitter = YES;
                }
            }
            else
            {
                shareOnTwitter = NO;
            }
            break;
        default:
            break;
    }
}


#pragma mark - facebook helpers
- (void)handleFBLogin
{
    shareOnFacebook = YES;
    [self._tableView reloadData];

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
}

#pragma mark - facebook delegate
- (void)sessionStateChanged:(NSNotification*)notification
{
    if(FBSession.activeSession.isOpen)
    {
        [self handleFBLogin];
    }
}

#pragma mark - twitter delegate
- (void)storeCachedTwitterOAuthData:(NSString *)data forUsername:(NSString *)username
{
	[appDelegate.prefs setObject:data forKey:@"TwitterAuthData"];
	[appDelegate.prefs synchronize];
    twitterIsAutherized = YES;
    shareOnTwitter = YES;
    [self._tableView reloadData];
}

- (NSString *)cachedTwitterOAuthDataForUsername:(NSString *)username
{
	return [appDelegate.prefs objectForKey:@"TwitterAuthData"];
}

- (void)OAuthTwitterController:(SA_OAuthTwitterController *)controller authenticatedWithUsername:(NSString *)username
{
	[appDelegate.prefs setObject:username forKey:@"twitterId"];
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
    //NSLog(@"requestSucceeded");
}

- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error
{
    //NSLog(@"requestFailed: %@", error);
}

#pragma mark - geo tag view controller delegate
- (void)setGeotagData:(NSDictionary*)geotagData
{
    isGeoTagged = YES;

    NSMutableDictionary *group0Dict = [listOfItems objectAtIndex:0];
    NSMutableArray *group0 = [group0Dict valueForKey:@"photoInfo"];
    NSIndexPath *updatePath;
    if(missionNo != nil)
    {
        if([group0 count] == 4)
        {
            [group0 replaceObjectAtIndex:3 withObject:[geotagData valueForKey:@"venueName"]];
        }
        else
        {
            [group0 addObject:[geotagData valueForKey:@"venueName"]];
        }
        updatePath = [NSIndexPath indexPathForRow:3 inSection:0];
    }
    else
    {
        if([group0 count] == 3)
        {
            [group0 replaceObjectAtIndex:2 withObject:[geotagData valueForKey:@"venueName"]];
        }
        else
        {
            [group0 addObject:[geotagData valueForKey:@"venueName"]];
        }
        updatePath = [NSIndexPath indexPathForRow:2 inSection:0];
    }

    self.locationName = [geotagData valueForKey:@"venueName"];
    self.locationId = [geotagData valueForKey:@"venueId"];
    latitude = [[geotagData valueForKey:@"latitude"] floatValue];
    longitude = [[geotagData valueForKey:@"longitude"] floatValue];

    [self._tableView beginUpdates];
    [self._tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:updatePath, nil] withRowAnimation:UITableViewRowAnimationNone];
    [self._tableView endUpdates];
}

#pragma mark - location delegate
- (void)locationUpdate:(CLLocation *)location
{
    [self.CLController setDelegate:nil];
    [CLController.locationManager stopUpdatingLocation];
	latitude = location.coordinate.latitude;
	longitude = location.coordinate.longitude;
    
    gpsIsWorking = NO;
    
    if(self.missionNo == nil)
    {
        NSIndexPath *reloadPath = [NSIndexPath indexPathForRow:1 inSection:0];
        NSArray *indexArray = [NSArray arrayWithObjects:reloadPath, nil];
        [self._tableView reloadRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationNone];
    }
    else
    {
        NSIndexPath *reloadPath = [NSIndexPath indexPathForRow:2 inSection:0];
        NSArray *indexArray = [NSArray arrayWithObjects:reloadPath, nil];
        [self._tableView reloadRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)locationError:(NSError *)error
{
	[CLController.locationManager stopUpdatingLocation];

    NSMutableDictionary *group0Dict = [listOfItems objectAtIndex:0];
    NSMutableArray *group0 = [group0Dict valueForKey:@"photoInfo"];
    
    if([group0 count] == 3)
    {
        [group0 removeObjectAtIndex:2];
    }

    gpsIsWorking = NO;
    isGeoTagged = NO;

    [self._tableView reloadData];
    
    NSDictionary *alertData = [[NSDictionary alloc] initWithObjectsAndKeys:@"Failed to get Location", @"title", @"Please make sure that location services are enabled in your device settings.", @"message", nil];
	[appDelegate displayAlert:alertData];
	[alertData release];
}

#pragma mark - keyboard delegate
- (void)keyboardWillShow:(NSNotification *)noif
{
    if(keyboardIsVisible == NO)
    {
        originalTableHeight = self._tableView.frame.size.height;
    }
    keyboardIsVisible = YES;
    
    // get keyboard size and loctaion
	CGRect keyboardBounds;
    [[noif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
	
	// get the height since this is the main value that we need.
	NSInteger kbSizeH = keyboardBounds.size.height;
    if(kbSizeH == [UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO])
    {
        kbSizeH = keyboardBounds.size.width;
    }
    
    // get a rect for the tableView frame
	CGRect tableFrame = self._tableView.frame;
	tableFrame.size.height = originalTableHeight - kbSizeH;
    
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.2f];
	
	// set views with new info
    self._tableView.frame = tableFrame;
	
	// commit animations
	[UIView commitAnimations];
}

-(void) keyboardWillHide:(NSNotification *)noif
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
	
	// get a rect for the tableView frame
	CGRect tableFrame = self._tableView.frame;
	tableFrame.size.height += kbSizeH;
	
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.2f];
	
	// set views with new info
	self._tableView.frame = tableFrame;
    
	// commit animations
	[UIView commitAnimations];
}

#pragma mark - text view delegate
- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView
{
    UILabel *placeholder = (UILabel*)[growingTextView viewWithTag:1];
    [placeholder setHidden:YES];
    return YES;
}

- (BOOL)growingTextViewShouldEndEditing:(HPGrowingTextView *)growingTextView
{
    UILabel *placeholder = (UILabel*)[growingTextView viewWithTag:1];
    if([[growingTextView text] isEqualToString:@""])
    {
        [placeholder setHidden:NO];
    }
    else
    {
        [placeholder setHidden:YES];
    }
    return YES;
}

- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView
{

}

- (void)growingTextViewDidEndEditing:(HPGrowingTextView *)growingTextView
{

}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if(range.length > text.length)
    {
        return YES;
    }
    else if([[growingTextView text] length] + text.length > 80)
    {
        return NO;
    }
    
    return YES;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    
}

- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)growingTextView
{
    [growingTextView resignFirstResponder];
    return YES;
}

@end