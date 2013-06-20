//
//  GeotagViewController.m
//  Wander
//
//  Created by Jiho Kang on 9/19/11.
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

#import "GeotagViewController.h"
#import "VenueResultCell.h"
#import "UtilityClasses.h"

@implementation GeotagViewController
@synthesize delegate;
@synthesize _tableView;
@synthesize searchIndicator;
@synthesize CLController;
@synthesize searchValue;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
        [operationQueue setSuspended:NO];
        
        locationData = [[NSMutableArray alloc] init];
        
        [self.navigationItem setCustomTitle:@"Geotag Photo"];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [locationData release];
	[jsonParser release];
    [operationQueue cancelAllOperations];
    [operationQueue release];
    [CLController release];
    [_tableView release];
    [searchIndicator release];
    [searchValue release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
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
    
    jsonParser = [[SBJsonParser alloc] init];
	

    if([locationData count] == 0)
    {
        self.CLController = [[[CoreLocationController alloc] init] autorelease];
        [self.CLController setDelegate:self];
        [self.CLController.locationManager startUpdatingLocation];
        [self showSearchIndicator];
    }
}

- (void)viewDidUnload
{    
    [jsonParser release];
    jsonParser = nil;

    [super viewDidUnload];

    self.CLController = nil;
    self.searchValue = nil;
    self._tableView = nil;
    self.searchIndicator = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [operationQueue cancelAllOperations];
    [super viewWillDisappear:animated];
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
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)getLocationInfo:(NSString*)name
{
    if([appDelegate.networkStatus boolValue] == NO)
    {
        return;
    }
    
	[appDelegate didStartNetworking];
    
    NSURL *url = nil;
    if(name != nil && ![name isEqualToString:@""])
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?query=%@&ll=%f,%f&client_id=%@&client_secret=%@&v=20110919", name, latitude, longitude, foursquareKey, foursquareSecret]];
    }
    else
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&client_id=%@&client_secret=%@&v=20110919", latitude, longitude, foursquareKey, foursquareSecret]];
    }
    
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:url];
    [request setAllowCompressedResponse:YES];
    [request setShouldWaitToInflateCompressedResponses:NO];
    [request setNumberOfTimesToRetryOnTimeout:2];
    [request setShouldAttemptPersistentConnection:NO];
    [request startSynchronous];
    [appDelegate didStopNetworking];
    
    NSError *error = [request error];
    
    NSArray *venues = nil;
    if (!error)
    {
        NSString *json_string = [request responseString];
        NSDictionary *apiResult = [jsonParser objectWithString:json_string error:nil];
        
        if([[[apiResult valueForKey:@"meta"] valueForKey:@"code"] intValue] == 200)
        {
            venues = [[apiResult valueForKey:@"response"] valueForKey:@"venues"];
        }
    }
    [request release];
    
    [self performSelectorOnMainThread:@selector(setLocationInfo:) withObject:venues waitUntilDone:NO];
}

- (void)setLocationInfo:(NSArray*)locationInfo
{
    [locationData removeAllObjects];
    [locationData addObjectsFromArray:locationInfo];
    [self.searchDisplayController setActive:NO];
    [self._tableView reloadData];
    [self hideSearchIndicator];
}

- (void)showSearchIndicator
{    
    [self.searchIndicator setFrame:CGRectMake(0, 44-searchIndicator.frame.size.height, searchIndicator.frame.size.width, searchIndicator.frame.size.height)];
    [self.searchIndicator setHidden:NO];
    
    [UIView beginAnimations:@"ShowSearchIndicator" context:nil];
    [UIView setAnimationDuration:0.25];
    [self.searchIndicator setFrame:CGRectMake(0, 44, self.view.frame.size.width, 25)];
    float newheight = (self.view.frame.size.height - 44) - 25;
    [self._tableView setFrame:CGRectMake(0, (44 + 25), self.view.frame.size.width, newheight)];
    [UIView commitAnimations];
}

- (void)hideSearchIndicator
{    
    [UIView beginAnimations:@"hideSearchIndicator" context:nil];
	[UIView setAnimationDuration:0.25];
	[self.searchIndicator setFrame:CGRectMake(0, 19, self.view.frame.size.width, 25)];
    float newheight = (self.view.frame.size.height - 44);
	[self._tableView setFrame:CGRectMake(0, 44, self.view.frame.size.width, newheight)];
	[UIView commitAnimations];
}

#pragma mark - search controller delegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	if([searchString isEqualToString:@""] == NO)
	{
        self.searchValue = nil;
		self.searchValue = searchString;
        [self.searchDisplayController.searchResultsTableView reloadData];
	}
	
	return NO;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	
}

#pragma mark - UITableView delegate and data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    if([self.searchDisplayController isActive] == NO)
    {
        return [locationData count];
    }
    else
    {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SearchCellIdentifier = @"SearchCellIdentifier";
	static NSString *ListCellIdentifier = @"ListCellIdentifier";
    static NSString *CellIdentifier = nil;
    
    if([self.searchDisplayController isActive] == NO)
    {
        CellIdentifier = ListCellIdentifier;
    }
    else
    {
        CellIdentifier = SearchCellIdentifier;
    }
	
	// Dequeue or create a cell of the appropriate type.
	VenueResultCell *cell = (VenueResultCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
    {
		NSArray *aCell = [[NSBundle mainBundle] loadNibNamed:@"VenueResultCell" owner:nil options:nil];
        if([self.searchDisplayController isActive] == NO)
        {
            cell = [aCell objectAtIndex:0];
        }
        else
        {
            cell = [aCell objectAtIndex:1];
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
	}
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];

	// Configure the cell
    if([self.searchDisplayController isActive] == NO)
    {
        NSDictionary *venueData = [locationData objectAtIndex:indexPath.row];
        NSString *address = [[venueData valueForKey:@"location"] valueForKey:@"address"];
        NSString *city = [[venueData valueForKey:@"location"] valueForKey:@"city"];
        int distance = [[[venueData valueForKey:@"location"] valueForKey:@"distance"] intValue];

        [cell.mainLabel setText:[venueData valueForKey:@"name"]];
        if(address && city)
        {
            [cell.subLabel setText:[NSString stringWithFormat:@"%@, %@", address, city]];
        }
        else if(city)
        {
            [cell.subLabel setText:city];
        }
        else
        {
            [cell.subLabel setText:[NSString stringWithFormat:@"%d meters from current location", distance]];
        }
    }
    else
    {
        if(indexPath.row == 0)
        {
            [cell.iconImageView setImage:[UIImage imageNamed:@"ico_placeadd.png"]];
            [cell.mainLabel setText:[NSString stringWithFormat:@"add \"%@\"", self.searchValue]];
            [cell.subLabel setText:@"Create a custom location"];
        }
        else
        {
            [cell.iconImageView setImage:[UIImage imageNamed:@"ico_placesearch.png"]];
            [cell.mainLabel setText:[NSString stringWithFormat:@"search for \"%@\"", self.searchValue]];
            [cell.subLabel setText:@"Search more places nearby"];
        }
    }

	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    if([self.searchDisplayController isActive] == NO)
    {
        title = @"Nearby";
    }
	return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if([self.searchDisplayController isActive] == NO)
    {
        NSDictionary *venueData = [locationData objectAtIndex:indexPath.row];
        NSString *venueId = [venueData valueForKey:@"id"];
        NSString *venueName = [venueData valueForKey:@"name"];
        NSNumber *venueLatitude = [NSNumber numberWithFloat:[[[venueData valueForKey:@"location"] valueForKey:@"lat"] floatValue]];
        NSNumber *venueLongitude = [NSNumber numberWithFloat:[[[venueData valueForKey:@"location"] valueForKey:@"lng"] floatValue]];

        NSDictionary *geotagData = [[NSDictionary alloc] initWithObjectsAndKeys:venueId, @"venueId", venueName, @"venueName", venueLatitude, @"latitude", venueLongitude, @"longitude", nil];

        [delegate setGeotagData:geotagData];
        
        [geotagData release];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        if(indexPath.row == 0)
        {
            NSNumber *venueLatitude = [NSNumber numberWithFloat:latitude];
            NSNumber *venueLongitude = [NSNumber numberWithFloat:longitude];
            
            NSDictionary *geotagData = [[NSDictionary alloc] initWithObjectsAndKeys:self.searchValue, @"venueName", venueLatitude, @"latitude", venueLongitude, @"longitude", nil];
            
            [delegate setGeotagData:geotagData];
            [geotagData release];

            [self.navigationController popViewControllerAnimated:YES];
        }
        else if(indexPath.row == 1)
        {
            [self showSearchIndicator];

            [operationQueue cancelAllOperations];
            NSInvocationOperation *theOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(getLocationInfo:) object:self.searchValue];
            [operationQueue addOperation:theOperation];
            [theOperation release];
        }
    }
}

#pragma mark - location delegate
- (void)locationUpdate:(CLLocation *)location
{
    [CLController.locationManager stopUpdatingLocation];
	latitude = location.coordinate.latitude;
	longitude = location.coordinate.longitude;

    [operationQueue cancelAllOperations];
    NSInvocationOperation *theOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(getLocationInfo:) object:nil];
    [operationQueue addOperation:theOperation];
    [theOperation release];
}

- (void)locationError:(NSError *)error
{
	[CLController.locationManager stopUpdatingLocation];
    [appDelegate hideLoading];
}

@end
