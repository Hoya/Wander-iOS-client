//
//  DebugSettingsViewController.m
//  Wander
//
//  Created by Jiho Kang on 11/18/11.
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

#import "DebugSettingsViewController.h"

@implementation DebugSettingsViewController
@synthesize listOfItems;
@synthesize _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
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
    [listOfItems release];
    [_tableView release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.navigationItem setCustomTitle:@"Debug"];
    
    // set table background to clear
	self._tableView.backgroundColor = [UIColor clearColor];
    
    // Initialize the array 
	self.listOfItems = [[[NSMutableArray alloc] init] autorelease];
    NSArray *group0 = [NSArray arrayWithObjects:@"Console Debug Mode", nil];
    NSDictionary *group0Dict = [NSDictionary dictionaryWithObject:group0 forKey:@"settings"];
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
    self._tableView = nil;
    self.listOfItems = nil;
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

- (void)didSwitch:(id)sender;
{
    if([sender isOn] == YES)
    {
        [appDelegate.prefs setValue:@"Y" forKey:@"consoleDebugMode"];
    }
    else
    {
        [appDelegate.prefs setValue:@"N" forKey:@"consoleDebugMode"];
    }
    [appDelegate.prefs synchronize];
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
	NSArray *array = [dictionary objectForKey:@"settings"];
	return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        [cell.textLabel setBackgroundColor:[UIColor clearColor]];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    // Configure the cell...
	NSDictionary *dictionary = [self.listOfItems objectAtIndex:indexPath.section];
	NSArray *array = [dictionary objectForKey:@"settings"];
	NSString *cellValue = [array objectAtIndex:indexPath.row];
	cell.textLabel.text = cellValue;
	cell.accessoryType = UITableViewCellAccessoryNone;

    UISwitch *_switch = [[UISwitch alloc] initWithFrame:CGRectMake(211, 8, 79, 27)];
    [_switch addTarget:self action:@selector(didSwitch:) forControlEvents:UIControlEventValueChanged];
    if([[appDelegate.prefs valueForKey:@"consoleDebugMode"] isEqualToString:@"Y"])
    {
        [_switch setOn:YES animated:NO];
    }
    else
    {
        [_switch setOn:NO animated:NO];
    }
    [cell.contentView addSubview:_switch];
    [_switch release];

    return cell;
}

@end
