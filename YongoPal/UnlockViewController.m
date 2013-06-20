//
//  UnlockViewController.m
//  Wander
//
//  Created by Jiho Kang on 10/24/11.
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

#import "UnlockViewController.h"

@implementation UnlockViewController
@synthesize listOfItems;
@synthesize _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];

        [self.navigationItem setCustomTitle:@"Unlock Features"];
        
        if(operationQueue == nil)
        {
            operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:1];
            [operationQueue setSuspended:NO];
        }
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
    [operationQueue cancelAllOperations];
    [operationQueue release];
    self.listOfItems = nil;
    self._tableView = nil;
    [super dealloc];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set table background to clear
	self._tableView.backgroundColor = [UIColor clearColor];

	// Initialize the array 
	self.listOfItems = [[[NSMutableArray alloc] init] autorelease];
    
    NSArray *group0 = [NSArray arrayWithObjects:@"Set Match Priority", @"Activate Quick Match", @"Set Daily Match Limit", nil];
	NSDictionary *group0Dict = [NSDictionary dictionaryWithObject:group0 forKey:@"unlock"];
    
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (void)setMatchPriority
{
    int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
    int matchPriority = [appDelegate.prefs integerForKey:@"matchPriority"];
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	[memberData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
    [memberData setValue:[NSString stringWithFormat:@"%d", matchPriority] forKey:@"matchPriority"];
	[appDelegate.apiRequest sendServerRequest:@"member" withTask:@"setMatchPriority" withData:memberData];
	[memberData release];
}

- (void)setQuickMatch
{
    int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	[memberData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
    if([[appDelegate.prefs valueForKey:@"quickMatchEnabled"] isEqualToString:@"Y"])
    {
        [memberData setValue:@"Y" forKey:@"quickMatch"];
    }
    else
    {
        [memberData setValue:@"N" forKey:@"quickMatch"];
    }
	[appDelegate.apiRequest sendServerRequest:@"member" withTask:@"setQuickMatch" withData:memberData];
	[memberData release];
}

- (void)setMatchLimit
{
    int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
    int matchLimit = [appDelegate.prefs integerForKey:@"matchLimit"];
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	[memberData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
    [memberData setValue:[NSString stringWithFormat:@"%d", matchLimit] forKey:@"matchLimit"];
	[appDelegate.apiRequest sendServerRequest:@"member" withTask:@"setMatchLimit" withData:memberData];
	[memberData release];
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
	NSArray *array = [dictionary objectForKey:@"unlock"];
	return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CellIdentifier2 = @"Cell2";

    SwitchCell *cell;
    if(indexPath.row == 1)
    {
        cell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    else
    {
        cell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
    }
    
    if (cell == nil)
    {
        NSArray *aCell = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:nil options:nil];
        
        if(indexPath.row == 1)
        {
            cell = [aCell objectAtIndex:0];
        }
        else
        {
            cell = [aCell objectAtIndex:1];
        }
    }
    
    NSDictionary *dictionary = [self.listOfItems objectAtIndex:indexPath.section];
	NSArray *array = [dictionary objectForKey:@"unlock"];
	NSString *cellValue = [array objectAtIndex:indexPath.row];
    
    cell.titleField.text = cellValue;
    cell.section = indexPath.section;
    cell.nIndex = indexPath.row;
    [cell setDelegate:self];
    
    if(indexPath.row == 1)
    {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if([[appDelegate.prefs valueForKey:@"quickMatchEnabled"] isEqualToString:@"Y"])
        {
            [cell.theSwitch setOn:YES];
        }
        else
        {
            [cell.theSwitch setOn:NO];
        }
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [cell.theSwitch setHidden:YES];
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        
        if(indexPath.row == 0)
        {
            int matchPriority = [appDelegate.prefs integerForKey:@"matchPriority"];
            if(matchPriority == 0)
            {
                matchPriority = 5;
            }
            [cell.subField setText:[NSString stringWithFormat:@"%d", matchPriority]];
        }
        else if(indexPath.row == 2)
        {
            int matchLimit = [appDelegate.prefs integerForKey:@"matchLimit"];
            if(matchLimit == 0)
            {
                matchLimit = 1;
            }
            [cell.subField setText:[NSString stringWithFormat:@"%d", matchLimit]];
        }
    }

    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.row == 0)
    {
        if([appDelegate.prefs integerForKey:@"matchPriority"] == 0)
        {
            [appDelegate.prefs setInteger:5 forKey:@"matchPriority"];
            [appDelegate.prefs synchronize];
        }
        InputViewController *inputController = [[InputViewController alloc] initWithNibName:@"InputViewController" bundle:nil];
        [inputController setNavTitle:@"Set Match Priority"];
        [inputController setKeyboardType:UIKeyboardTypeNumberPad];
        [inputController setTag:indexPath.row];
        [inputController setDelegate:self];
        NSString *defaultValue = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"matchPriority"]];
        [inputController setDefaultInputValue:defaultValue];
        [self.navigationController pushViewController:inputController animated:YES];
        [inputController release];
    }
    else if(indexPath.row == 2)
    {
        if([appDelegate.prefs integerForKey:@"matchLimit"] == 0)
        {
            [appDelegate.prefs setInteger:1 forKey:@"matchLimit"];
            [appDelegate.prefs synchronize];
        }
        InputViewController *inputController = [[InputViewController alloc] initWithNibName:@"InputViewController" bundle:nil];
        [inputController setNavTitle:@"Set Daily Match Limit"];
        [inputController setKeyboardType:UIKeyboardTypeNumberPad];
        [inputController setTag:indexPath.row];
        [inputController setDelegate:self];
        NSString *defaultValue = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"matchLimit"]];
        [inputController setDefaultInputValue:defaultValue];
        [self.navigationController pushViewController:inputController animated:YES];
        [inputController release];
    }
}

#pragma mark - Notification cell delegate
- (void)switchTouched:(BOOL)status atIndexPath:(NSIndexPath*)indexPath
{
    if(status == YES)
    {
        [appDelegate.prefs setValue:@"Y" forKey:@"quickMatchEnabled"];
    }
    else
    {
        [appDelegate.prefs setValue:@"N" forKey:@"quickMatchEnabled"];
    }
	[appDelegate.prefs synchronize];
    
    NSInvocationOperation *quickMatchOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setQuickMatch) object:nil];
    [operationQueue addOperation:quickMatchOperation];
    [quickMatchOperation release];
}

#pragma mark - Input view controller delegate
- (void)valueSet:(NSString*)value sender:(int)tag
{
    if(tag == 0)
    {
        [appDelegate.prefs setInteger:[value intValue] forKey:@"matchPriority"];
        [appDelegate.prefs synchronize];

        NSInvocationOperation *quickMatchOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setMatchPriority) object:nil];
        [operationQueue addOperation:quickMatchOperation];
        [quickMatchOperation release];
    }
    else if(tag == 2)
    {
        [appDelegate.prefs setInteger:[value intValue] forKey:@"matchLimit"];
        [appDelegate.prefs synchronize];

        NSInvocationOperation *quickMatchOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setMatchLimit) object:nil];
        [operationQueue addOperation:quickMatchOperation];
        [quickMatchOperation release];
    }
    [self._tableView reloadData];
}

@end
