//
//  MatchOptionsViewController.m
//  Wander
//
//  Created by Jiho Kang on 2/8/12.
//  Copyright (c) 2012 YongoPal, Inc. All rights reserved.
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

#import "MatchOptionsViewController.h"

@implementation MatchOptionsViewController
@synthesize listOfItems;
@synthesize _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        [self.navigationItem setCustomTitle:NSLocalizedString(@"optionsTitle", nil)];
        
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:4];
        [operationQueue setSuspended:NO];
        
        NSString *suspended = [appDelegate.prefs valueForKey:@"suspended"];
        NSString *quickMatchEnabled = [appDelegate.prefs valueForKey:@"quickMatchEnabled"];
        
        matchOptions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:suspended, @"isSuspend", quickMatchEnabled, @"quickMatchEnabled", nil];
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
    
    // set table background to clear
	self._tableView.backgroundColor = [UIColor clearColor];
    
	// Initialize the array 
	self.listOfItems = [[[NSMutableArray alloc] init] autorelease];
    
	NSArray *group0 = [NSArray arrayWithObjects:NSLocalizedString(@"enableQuickMatch", nil), nil];
	NSDictionary *group0Dict = [NSDictionary dictionaryWithObject:group0 forKey:@"noif"];
    [self.listOfItems addObject:group0Dict];
    
    NSArray *group1 = [NSArray arrayWithObjects:NSLocalizedString(@"stopWanderingMenu", nil), nil];
	NSDictionary *group1Dict = [NSDictionary dictionaryWithObject:group1 forKey:@"noif"];
    [self.listOfItems addObject:group1Dict];
	
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (void)dealloc
{
    [operationQueue cancelAllOperations];
    [operationQueue release];
	[listOfItems release];
	[_tableView release];
    [matchOptions release];
    [super dealloc];
}


- (void)goBack
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)registerSuspended:(NSIndexPath*)indexPath
{
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
    [memberData setValue:memberNoString forKey:@"memberNo"];
	[memberData setValue:[appDelegate.prefs valueForKey:@"active"] forKey:@"active"];
	[memberData setValue:[matchOptions valueForKey:@"isSuspend"] forKey:@"suspend"];
	
	NSDictionary *results = [appDelegate.apiRequest sendServerRequest:@"member" withTask:@"setUserSuspended" withData:memberData];
	[memberData release];
    
    if(results)
    {
        if([results valueForKey:@"updatedRows"] != [NSNull null] && [results valueForKey:@"updatedRows"] != nil)
        {
            [self performSelectorOnMainThread:@selector(doneRegisteringOption:) withObject:indexPath waitUntilDone:NO];
        }
    }
}

- (void)registerQuickMatch:(NSIndexPath*)indexPath
{
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[memberData setValue:memberNoString forKey:@"memberNo"];
	[memberData setValue:[matchOptions valueForKey:@"quickMatchEnabled"] forKey:@"quickMatch"];
	
	NSDictionary *results = [appDelegate.apiRequest sendServerRequest:@"member" withTask:@"setQuickMatch" withData:memberData];
	[memberData release];
    
    if(results)
    {
        if([results valueForKey:@"updatedRows"] != [NSNull null] && [results valueForKey:@"updatedRows"] != nil)
        {
            [self performSelectorOnMainThread:@selector(doneRegisteringOption:) withObject:indexPath waitUntilDone:NO];
        }
    }
}

- (void)doneRegisteringOption:(NSIndexPath*)indexPath
{
    NSString *isSuspend = [matchOptions valueForKey:@"isSuspend"];
    NSString *quickMatchEnabled = [matchOptions valueForKey:@"quickMatchEnabled"];
    
    [appDelegate.prefs setValue:isSuspend forKey:@"suspended"];
    [appDelegate.prefs setValue:quickMatchEnabled forKey:@"quickMatchEnabled"];
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
    
	if(indexPath.section == 0)
	{
		NSString *optionEnabled = [matchOptions objectForKey:@"quickMatchEnabled"];
		bool enabled = YES;
        if([optionEnabled isEqualToString:@"N"]) enabled = NO;
		[cell.theSwitch setOn:enabled];

	}
    else if(indexPath.section == 1)
	{
        NSString *optionEnabled = [matchOptions objectForKey:@"isSuspend"];
		bool enabled = YES;
        if([optionEnabled isEqualToString:@"N"]) enabled = NO;
		[cell.theSwitch setOn:enabled];
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] init];
    UILabel *footerLabel = [[UILabel alloc] init];
    [footerLabel setFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:12.0]];
    [footerLabel setLineBreakMode:UILineBreakModeWordWrap];
    [footerLabel setNumberOfLines:10];
    [footerLabel setBackgroundColor:[UIColor clearColor]];

    if(section == 0)
    {
        [footerView setFrame:CGRectMake(0, 0, 320, 120)];
        [footerLabel setFrame:CGRectMake(20, 10, 280, 100)];
        [footerLabel setText:@"If you enable Quick Match, you will be automatically connected to the next available guide from somewhere in the world. If you disable Quick Match you will have the option to say Yes or No to each daily guide but you might have to wait longer for a successful match."];
    }
    else
    {
        [footerView setFrame:CGRectMake(0, 0, 320, 80)];
        [footerLabel setFrame:CGRectMake(20, 10, 280, 60)];
        [footerLabel setText:@"Switch this option on if you DON'T want to receive new guides each day anymore. You can switch this option off later when you want to receive daily guides again."];
    }
    [footerView addSubview:footerLabel];
    [footerLabel release];
    
    return [footerView autorelease];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(section == 0)
    {
        return 120;
    }
    else
    {
        return 80;
    }
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
    
	if(indexPath.section == 0)
	{
		[matchOptions setValue:statusString forKey:@"quickMatchEnabled"];
        NSInvocationOperation *registerOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(registerQuickMatch:) object:indexPath];
        [operationQueue addOperation:registerOperation];
        [registerOperation release];
	}
    else if(indexPath.section == 1)
	{
        [matchOptions setValue:statusString forKey:@"isSuspend"];
        NSInvocationOperation *registerOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(registerSuspended:) object:indexPath];
        [operationQueue addOperation:registerOperation];
        [registerOperation release];
    }
}

@end
