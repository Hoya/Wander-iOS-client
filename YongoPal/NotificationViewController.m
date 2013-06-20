//
//  NotificationViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 5/16/11.
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

#import "NotificationViewController.h"


@implementation NotificationViewController
@synthesize listOfItems;
@synthesize _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        [self.navigationItem setCustomTitle:NSLocalizedString(@"notificationTitle", nil)];
        
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:4];
        [operationQueue setSuspended:NO];
        
        NSString *newMatchAlert = [appDelegate.prefs valueForKey:@"newMatchAlertStatus"];
        NSString *newMissionAlert = [appDelegate.prefs valueForKey:@"newMissionAlertStatus"];
        NSString *newMessageAlert = [appDelegate.prefs valueForKey:@"newMessageAlertStatus"];
        
        pushSettings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:newMatchAlert, @"newMatchAlertStatus", newMissionAlert, @"newMissionAlertStatus", newMessageAlert, @"newMessageAlertStatus", nil];
    }
    return self;
}

- (void)dealloc
{
    [operationQueue cancelAllOperations];
    [operationQueue release];
	[listOfItems release];
	[_tableView release];
    [pushSettings release];
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
    // Do any additional setup after loading the view from its nib.
    
    // set table background to clear
	self._tableView.backgroundColor = [UIColor clearColor];
    
	// Initialize the array 
	self.listOfItems = [[[NSMutableArray alloc] init] autorelease];
    
	NSArray *group0 = [NSArray arrayWithObjects:NSLocalizedString(@"matchAlertsMenu", nil), NSLocalizedString(@"missionAlertsMenu", nil), NSLocalizedString(@"messageAlertsMenu", nil), nil];
	NSDictionary *group0Dict = [NSDictionary dictionaryWithObject:group0 forKey:@"noif"];
    
	[self.listOfItems addObject:group0Dict];
	
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.listOfItems = nil;
	self._tableView = nil;
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

- (void)goBack
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)registerNotificationStatus:(NSIndexPath*)indexPath
{
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
	[memberData setValue:[pushSettings valueForKey:@"newMatchAlertStatus"] forKey:@"newMatchAlert"];
    [memberData setValue:[pushSettings valueForKey:@"newMissionAlertStatus"] forKey:@"newMissionAlert"];
	[memberData setValue:[pushSettings valueForKey:@"newMessageAlertStatus"] forKey:@"newMessageAlert"];
	
	NSDictionary *results = [appDelegate.apiRequest sendServerRequest:@"member" withTask:@"registerPush" withData:memberData];
	[memberData release];
    
    if(results)
    {
        if([results valueForKey:@"updatedRows"] != [NSNull null] && [results valueForKey:@"updatedRows"] != nil)
        {
            [self performSelectorOnMainThread:@selector(doneRegisteringNotifications:) withObject:indexPath waitUntilDone:NO];
        }
    }
}

- (void)doneRegisteringNotifications:(NSIndexPath*)indexPath
{
    NSString *newMatchAlert = [pushSettings valueForKey:@"newMatchAlertStatus"];
    NSString *newMissionAlert = [pushSettings valueForKey:@"newMissionAlertStatus"];
    NSString *newMessageAlert = [pushSettings valueForKey:@"newMessageAlertStatus"];

    [appDelegate.prefs setValue:newMatchAlert forKey:@"newMatchAlertStatus"];
    [appDelegate.prefs setValue:newMissionAlert forKey:@"newMissionAlertStatus"];
    [appDelegate.prefs setValue:newMessageAlert forKey:@"newMessageAlertStatus"];
    [appDelegate.prefs synchronize];
    
    SwitchCell *cell = (SwitchCell*)[self._tableView cellForRowAtIndexPath:indexPath];
    
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[cell viewWithTag:10];
    
    [spinner stopAnimating];
    [cell.theSwitch setHidden:NO];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.listOfItems count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSDictionary *dictionary = [self.listOfItems objectAtIndex:section];
	NSArray *array = [dictionary objectForKey:@"noif"];
	return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    SwitchCell *cell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) {
		NSArray *aCell = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:nil options:nil];
		cell = [aCell objectAtIndex:0];
	}

    // Configure the cell...
	NSDictionary *dictionary = [self.listOfItems objectAtIndex:indexPath.section];
	NSArray *array = [dictionary objectForKey:@"noif"];
	NSString *cellValue = [array objectAtIndex:indexPath.row];
	cell.titleField.text = cellValue;
	cell.section = indexPath.section;
	cell.nIndex = indexPath.row;
	[cell setDelegate:self];

	if(indexPath.row == 0)
	{
		NSString *alertEnabled = [pushSettings objectForKey:@"newMatchAlertStatus"];
		bool enabled = YES;
        if([alertEnabled isEqualToString:@"N"]) enabled = NO;
		[cell.theSwitch setOn:enabled];
	}
    else if(indexPath.row == 1)
	{
		NSString *alertEnabled = [pushSettings objectForKey:@"newMissionAlertStatus"];
		bool enabled = YES;
        if([alertEnabled isEqualToString:@"N"]) enabled = NO;
		[cell.theSwitch setOn:enabled];
	}
	else if(indexPath.row == 2)
	{
		NSString *badgeEnabled = [pushSettings objectForKey:@"newMessageAlertStatus"];
        bool enabled = YES;
        if([badgeEnabled isEqualToString:@"N"]) enabled = NO;
		[cell.theSwitch setOn:enabled];
	}

    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

#pragma mark - Notification cell delegate
- (void)switchTouched:(BOOL)status atIndexPath:(NSIndexPath*)indexPath
{
    SwitchCell *cell = (SwitchCell*)[self._tableView cellForRowAtIndexPath:indexPath];
    
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[cell viewWithTag:10];

    [spinner startAnimating];
    [cell.theSwitch setHidden:YES];
    
	NSString *statusString = nil;
	if(status == YES) statusString = @"Y";
	else statusString = @"N";

	if(indexPath.row == 0)
	{
		[pushSettings setValue:statusString forKey:@"newMatchAlertStatus"];
	}
    else if(indexPath.row == 1)
	{
		[pushSettings setValue:statusString forKey:@"newMissionAlertStatus"];
	}
	else if(indexPath.row == 2)
	{
		[pushSettings setValue:statusString forKey:@"newMessageAlertStatus"];
	}

    NSInvocationOperation *registerOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(registerNotificationStatus:) object:indexPath];
    [operationQueue addOperation:registerOperation];
    [registerOperation release];
}

@end
