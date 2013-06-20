//
//  LocationPickerViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 6/20/11.
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

#import "LocationPickerViewController.h"


@implementation LocationPickerViewController
@synthesize delegate;
@synthesize cityName;
@synthesize provinceName;
@synthesize provinceCode;
@synthesize countryName;
@synthesize countryCode;
@synthesize timezone;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
        [operationQueue setSuspended:NO];
    }
    return self;
}

- (void)dealloc
{
	[locationData release];
	[jsonParser release];
    [operationQueue cancelAllOperations];
    [operationQueue release];

	[cityName release];
	[provinceName release];
	[provinceCode release];
	[countryName release];
	[countryCode release];
	[timezone release];
	
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

    [self.navigationItem setCustomTitle:NSLocalizedString(@"findLocationTitle", nil)];

	UIImage *cancelImage = [UIImage imageNamed:@"btn_x.png"];
	CGRect cancelFrame = CGRectMake(0, 0, cancelImage.size.width, cancelImage.size.height);
	CUIButton *cancelButton = [[CUIButton alloc] initWithFrame:cancelFrame];
	[cancelButton setBackgroundImage:cancelImage forState:UIControlStateNormal];
	[cancelButton setShowsTouchWhenHighlighted:YES];
	[cancelButton addTarget:self action:@selector(cancelLocation) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
	[self.navigationItem setLeftBarButtonItem:cancelBarButtonItem];
	[cancelBarButtonItem release];
	[cancelButton release];
	
	jsonParser = [[SBJsonParser alloc] init];
	locationData = [[NSMutableArray alloc] init];
}

- (void)viewDidUnload
{
    [locationData release];
    locationData = nil;

    [jsonParser release];
    jsonParser = nil;
    
    [super viewDidUnload];
    
    self.cityName = nil;
	self.provinceName = nil;
	self.provinceCode = nil;
	self.countryName = nil;
	self.countryCode = nil;
	self.timezone = nil;
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
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(searchOperation:) userInfo:searchString repeats:NO];
	
	return NO;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
	[self.searchDisplayController.searchResultsTableView setBackgroundColor:[UIColor clearColor]];
	[self.searchDisplayController.searchResultsTableView setSeparatorColor:[UIColor clearColor]];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	[operationQueue cancelAllOperations];
	NSInvocationOperation *theOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(mockSearch:) object:[searchBar text]];
	[operationQueue addOperation:theOperation];
	[theOperation release];
}

- (void)cancelLocation
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)searchOperation:(NSTimer*)timer
{
	NSString *searchString = timer.userInfo;
	[operationQueue cancelAllOperations];
	NSInvocationOperation *theOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(mockSearch:) object:searchString];
	[operationQueue addOperation:theOperation];
	[theOperation release];
}

- (void)mockSearch:(NSString*)queryString
{
    if([appDelegate.networkStatus boolValue] == NO)
    {
        [operationQueue cancelAllOperations];
        return;
    }

	if([queryString isEqualToString:@""] == NO)
	{
		[appDelegate didStartNetworking];
		
		NSString *query = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)queryString, NULL, NULL, kCFStringEncodingUTF8);
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?address=%@&sensor=false", query]];
		[query release];
		ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:url];
		[request setAllowCompressedResponse:YES];
		[request setShouldWaitToInflateCompressedResponses:NO];
		[request setNumberOfTimesToRetryOnTimeout:2];
		[request setShouldAttemptPersistentConnection:YES];
		[request startSynchronous];
		[appDelegate didStopNetworking];
		
		NSError *error = [request error];
		
		if (!error)
		{
			NSString *json_string = [request responseString];
            NSDictionary *apiResult = [jsonParser objectWithString:json_string error:nil];

            NSString *status = [apiResult valueForKey:@"status"];
            if([status isEqualToString:@"OK"])
            {
                NSArray *resultArray = [apiResult valueForKey:@"results"];
                NSMutableArray *locationArray = [[NSMutableArray alloc] init];

                for (NSDictionary *locationDic in resultArray)
                {
                    NSArray *components = [locationDic valueForKey:@"address_components"];
                    NSDictionary *geometry = [locationDic valueForKey:@"geometry"];
                    
                    NSDictionary *location = [geometry valueForKey:@"location"];
                    NSMutableDictionary *filteredLocation = [NSMutableDictionary dictionary];
                    [filteredLocation setValue:[location valueForKey:@"lat"] forKey:@"lat"];
                    [filteredLocation setValue:[location valueForKey:@"lng"] forKey:@"lng"];

                    for(NSDictionary *params in components)
                    {
                        NSPredicate *localityFilter = [NSPredicate predicateWithFormat:@"SELF contains[c] 'locality'"];
                        NSPredicate *level1Filter = [NSPredicate predicateWithFormat:@"SELF contains[c] 'administrative_area_level_1'"];
                        NSPredicate *countryFilter = [NSPredicate predicateWithFormat:@"SELF contains[c] 'country'"];
                        
                        NSArray *types = [params valueForKey:@"types"];
                        if([[types filteredArrayUsingPredicate:localityFilter] count] > 0)
                        {
                            [filteredLocation setValue:[params valueForKey:@"long_name"] forKey:@"cityName"];
                        }
                        
                        if([[types filteredArrayUsingPredicate:level1Filter] count] > 0)
                        {                            
                            [filteredLocation setValue:[params valueForKey:@"long_name"] forKey:@"provinceName"];
                            if([[params valueForKey:@"short_name"] length] < 5)
                            {
                                [filteredLocation setValue:[params valueForKey:@"short_name"] forKey:@"provinceCode"];
                            }
                        }
                        
                        if([[types filteredArrayUsingPredicate:countryFilter] count] > 0)
                        {
                            [filteredLocation setValue:[params valueForKey:@"short_name"] forKey:@"countryCode"];
                            [filteredLocation setValue:[params valueForKey:@"long_name"] forKey:@"countryName"];
                        }
                    }
                    
                    // get timezone
                    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
                    NSURLRequest *timezoneRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/timezone/json?location=%f,%f&timestamp=%f&sensor=false",[[location valueForKey:@"lat"] floatValue], [[location valueForKey:@"lng"] floatValue], timestamp]]];
                    NSData *timezoneResponse = [NSURLConnection sendSynchronousRequest:timezoneRequest returningResponse:nil error:&error];
                    [appDelegate didStopNetworking];
                    
                    json_string = [[NSString alloc] initWithData:timezoneResponse encoding:NSUTF8StringEncoding];
                    apiResult = [jsonParser objectWithString:json_string error:nil];
                    NSString *timeZoneId = [apiResult valueForKey:@"timeZoneId"];
                    [json_string release];

                    [filteredLocation setValue:timeZoneId forKey:@"timezone"];
                    
                    if([filteredLocation valueForKey:@"cityName"])
                    {
                        [locationArray addObject:filteredLocation];
                    }
                }
                [locationData removeAllObjects];
                [locationData setArray:locationArray];
                [self.searchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                [locationArray release];
            }
            else
            {
                [locationData removeAllObjects];
                [self.searchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            }
		}
		else
		{
			[locationData removeAllObjects];
			[self.searchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		}
		[request release];
        
        if([locationData count] == 0 && ![queryString hasSuffix:@"city"])
        {
            [self mockSearch:[NSString stringWithFormat:@"%@ city", queryString]];
        }
	}
}

#pragma mark - UITableView delegate and data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return [locationData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"CellIdentifier";
	
	// Dequeue or create a cell of the appropriate type.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	
	UITableViewCell *bgView = [[UITableViewCell alloc] initWithFrame:CGRectZero];
	bgView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
	cell.backgroundView = bgView;
	[bgView release];
	
	// Configure the cell
	NSDictionary *locationDic = [[locationData objectAtIndex:indexPath.row] copy];
	
	NSString *theCityName = [locationDic valueForKey:@"cityName"];
	NSString *theProvinceName = [locationDic valueForKey:@"provinceName"];
	NSString *theCountryName = [locationDic valueForKey:@"countryCode"];
	
	if(([theProvinceName isEqualToString:@""] || [theProvinceName isEqualToString:theCityName]) || !theProvinceName)
	{
		cell.textLabel.text = [NSString stringWithFormat:@"%@, %@", theCityName, theCountryName];
	}
	else
	{
		cell.textLabel.text = [NSString stringWithFormat:@"%@(%@), %@", theCityName, theProvinceName, theCountryName];
	}
	[locationDic release];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self.searchDisplayController setActive:NO];
	
	NSDictionary *locationDic = [locationData objectAtIndex:indexPath.row];
	self.cityName = [locationDic valueForKey:@"cityName"];
    if([locationDic valueForKey:@"provinceName"])
    {
        self.provinceName = [locationDic valueForKey:@"provinceName"];
        self.provinceCode = [[locationDic valueForKey:@"provinceCode"] stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    }
	self.countryName = [locationDic valueForKey:@"countryName"];
	self.countryCode = [locationDic valueForKey:@"countryCode"];
	self.timezone = [locationDic valueForKey:@"timezone"];

	latitude = [[locationDic valueForKey:@"lat"] floatValue];
	longitude = [[locationDic valueForKey:@"lng"] floatValue];

	if(([self.provinceName isEqualToString:@""] || [self.provinceName isEqualToString:self.cityName]) || !self.provinceName)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"isThisYourLocationPrompt", nil) message:[NSString stringWithFormat:@"%@\n%@", self.cityName, self.countryName] delegate:self cancelButtonTitle:NSLocalizedString(@"noButton", nil) otherButtonTitles:NSLocalizedString(@"yesButton", nil), nil];
		[alert setTag:1];
		[alert show];
		[alert release];
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"isThisYourLocationPrompt", nil) message:[NSString stringWithFormat:@"%@, %@\n%@", self.cityName, self.provinceName, self.countryName] delegate:self cancelButtonTitle:NSLocalizedString(@"noButton", nil) otherButtonTitles:NSLocalizedString(@"yesButton", nil), nil];
		[alert setTag:1];
		[alert show];
		[alert release];
	}
}

#pragma mark - alertView delegate
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == 1)
	{
		[operationQueue cancelAllOperations];
		
		[delegate setCityNameValue:self.cityName];
		[delegate setProvinceNameValue:self.provinceName];
		[delegate setProvinceCodeValue:self.provinceCode];
		[delegate setCountryNameValue:self.countryName];
		[delegate setCountryCodeValue:self.countryCode];
		[delegate setTimezoneValue:self.timezone];
        [delegate setLatitude:latitude];
        [delegate setLongitude:longitude];
		[delegate setLocationData];

		[self dismissModalViewControllerAnimated:YES];
	}
}

@end
