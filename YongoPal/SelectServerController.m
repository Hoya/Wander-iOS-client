//
//  SelectServerController.m
//  Wander
//
//  Created by Jiho Kang on 9/27/11.
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

#import "SelectServerController.h"

@implementation SelectServerController
@synthesize _tableView;
@synthesize listOfItems;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        [self.navigationItem setCustomTitle:@"Select Server"];
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

    self.listOfItems = [[[NSMutableArray alloc] init] autorelease];

	NSArray *group0 = [NSArray arrayWithObjects:@"Maruta", @"James", nil];
	NSDictionary *group0Dict = [NSDictionary dictionaryWithObject:group0 forKey:@"development"];

    NSArray *group1 = [NSArray arrayWithObjects:@"Debug", @"Beta (Debug)", @"Beta", @"Release (Debug)", @"Release", nil];
	NSDictionary *group1Dict = [NSDictionary dictionaryWithObject:group1 forKey:@"development"];

	[self.listOfItems addObject:group0Dict];
    [self.listOfItems addObject:group1Dict];
    
    UIImage *backImage = [UIImage imageNamed:@"btn_back.png"];
	CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
	UIButton *backButton = [[UIButton alloc] initWithFrame:backFrame];
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

- (void)dealloc
{
    [_tableView release];
    [listOfItems release];
    [super dealloc];
}

- (void)goBack
{
	[self.navigationController popViewControllerAnimated:YES];
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
	NSArray *array = [dictionary objectForKey:@"development"];
	return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    // Configure the cell...
	NSDictionary *dictionary = [self.listOfItems objectAtIndex:indexPath.section];
	NSArray *array = [dictionary objectForKey:@"development"];
	NSString *cellValue = [array objectAtIndex:indexPath.row];
	cell.textLabel.text = cellValue;
    
#warning these need to be filled in
    if([appDelegate.apiHost isEqualToString:@""] && indexPath.section == 0 && indexPath.row == 0)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if([appDelegate.apiHost isEqualToString:@""] && indexPath.section == 0 && indexPath.row == 1)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if([appDelegate.productionStage isEqualToString:@""] && indexPath.section == 1 && indexPath.row == 0)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if([appDelegate.productionStage isEqualToString:@""] && indexPath.section == 1 && indexPath.row == 1)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if([appDelegate.productionStage isEqualToString:@""] && indexPath.section == 1 && indexPath.row == 2)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if([appDelegate.productionStage isEqualToString:@""] && indexPath.section == 1 && indexPath.row == 3)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if([appDelegate.productionStage isEqualToString:@""] && indexPath.section == 1 && indexPath.row == 4)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;
	switch (section)
	{
		case 0:
			title = @"API Server";
			break;
		case 1:
			title = @"Production Stage";
			break;
		default:
			break;
	}
	return title;
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
#warning these need to be filled in
    if(indexPath.section == 0 && indexPath.row == 0)
    {
        appDelegate.apiHost = @"";
    }
    else if(indexPath.section == 0 && indexPath.row == 1)
    {
        appDelegate.apiHost = @"";
    }
    else if(indexPath.section == 1 && indexPath.row == 0)
    {
        appDelegate.productionStage = @"";
    }
    else if(indexPath.section == 1 && indexPath.row == 1)
    {
        appDelegate.productionStage = @"";
    }
    else if(indexPath.section == 1 && indexPath.row == 2)
    {
        appDelegate.productionStage = @"";
    }
    else if(indexPath.section == 1 && indexPath.row == 3)
    {
        appDelegate.productionStage = @"";
    }
    else if(indexPath.section == 1 && indexPath.row == 4)
    {
        appDelegate.productionStage = @"";
    }
    [self._tableView reloadData];
}

@end
