//
//  LogListController.m
//  YongoPal
//
//  Created by Jiho Kang on 7/13/11.
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

#import "LogListController.h"
#import "LogViewController.h"
#import "ApiLogs.h"
#import "LogListCell.h"

@implementation LogListController
@synthesize _tableView;
@synthesize resultsController;
@synthesize logFilter;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        [self.navigationItem setCustomTitle:@"API Logs"];
    }
    return self;
}

- (void)dealloc
{
	[_tableView release];
	[resultsController release];
    [logFilter release];
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
	
	/*
	NSFetchRequest *allApiLogData = [[NSFetchRequest alloc] init];
	[allApiLogData setEntity:[NSEntityDescription entityForName:@"ApiLogs" inManagedObjectContext:context]];
	NSError *error = nil;
	NSArray *apiLogArray = [context executeFetchRequest:allApiLogData error:&error];
	[allApiLogData release];
	for (ApiLogs *logData in apiLogArray)
	{
		NSString *logString = [NSString stringWithFormat:@"\n-----------------"];
		logString = [NSString stringWithFormat:@"%@\n*server:%@", logString, [logData valueForKey:@"server"]];
		logString = [NSString stringWithFormat:@"%@\n*request: %@", logString, [logData valueForKey:@"requestType"]];
		logString = [NSString stringWithFormat:@"%@\n*task:%@", logString, [logData valueForKey:@"task"]];
		logString = [NSString stringWithFormat:@"%@\n*requestData:%@", logString, [logData valueForKey:@"requestData"]];
		logString = [NSString stringWithFormat:@"%@\n*resultData:%@", logString, [logData valueForKey:@"resultData"]];
		logString = [NSString stringWithFormat:@"%@\n*date:%@", logString, [logData valueForKey:@"datetime"]];
		logString = [NSString stringWithFormat:@"%@\n-----------------\n", logString];

		[logView setText:[NSString stringWithFormat:@"%@%@", [logView text], logString]];
	}
	 */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // get rid of old logs
	NSTimeInterval secondsPerDay = 24 * 60 * 60;
	NSDate *yesterday = [[NSDate date] addTimeInterval:-secondsPerDay];
	
	NSError *error = nil;
	NSFetchRequest *allLogData = [[NSFetchRequest alloc] init];
	[allLogData setEntity:[NSEntityDescription entityForName:@"ApiLogs" inManagedObjectContext:appDelegate.managedObjectContext]];
	[allLogData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"datetime < %@", yesterday];
	[allLogData setPredicate:predicate];
    
	NSArray *logArray = [appDelegate.managedObjectContext executeFetchRequest:allLogData error:&error];
	[allLogData release];
	for (NSManagedObject *log in logArray)
	{
		[appDelegate.managedObjectContext deleteObject:log];
	}
	[appDelegate saveContext:appDelegate.mainMOC];
	
	// fetch logs
	NSFetchRequest *logRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ApiLogs" inManagedObjectContext:appDelegate.managedObjectContext];
	[logRequest setEntity:entity];
	
	NSSortDescriptor *sortDescripter = [[NSSortDescriptor alloc] initWithKey:@"datetime" ascending:NO];
	NSArray *sortDescripters = [[NSArray alloc] initWithObjects:sortDescripter, nil];
	[logRequest setSortDescriptors:sortDescripters];
	[sortDescripters release];
	[sortDescripter release];
	
    [NSFetchedResultsController deleteCacheWithName:@"apiLogs.cache"];
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] 
															initWithFetchRequest:logRequest 
															managedObjectContext:appDelegate.managedObjectContext 
															sectionNameKeyPath:nil
															cacheName:@"apiLogs.cache"];
	[logRequest release];
    
	BOOL success = [fetchedResultsController performFetch:&error];
	if(!success)
	{
		NSLog(@"error: %@", error);
	}
	self.resultsController = fetchedResultsController;
    [self.resultsController setDelegate:self];
	[fetchedResultsController release];
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.resultsController = nil;
    [super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self._tableView = nil;
	self.resultsController = nil;
    self.logFilter = nil;
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

- (IBAction)filterChanged:(id)sender
{
    NSError *error = nil;
    [NSFetchedResultsController deleteCacheWithName:@"apiLogs.cache"];
    if([sender selectedSegmentIndex] == 0)
    {
        [self.resultsController.fetchRequest setPredicate:nil];
        
        BOOL success = [self.resultsController performFetch:&error];
        if(!success)
        {
            NSLog(@"error: %@", error);
        }
    }
    else if([sender selectedSegmentIndex] == 1)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isError = YES"];
        [self.resultsController.fetchRequest setPredicate:predicate];
        BOOL success = [self.resultsController performFetch:&error];
        if(!success)
        {
            NSLog(@"error: %@", error);
        }
    }

    [self._tableView reloadData];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	return [[[self.resultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
	
	LogListCell *cell = (LogListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) {
		NSArray *aCell = [[NSBundle mainBundle] loadNibNamed:@"LogListCell" owner:nil options:nil];
		cell = [aCell objectAtIndex:0];
	}
    
    // Configure the cell...
	ApiLogs *logData = [self.resultsController objectAtIndexPath:indexPath];
	NSString *type = [logData valueForKey:@"requestType"];
	NSString *task = [logData valueForKey:@"task"];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MM/dd HH:mm:ssZ"];
	NSString *date = [dateFormatter stringFromDate:[logData valueForKey:@"datetime"]];
    [dateFormatter release];

	[cell.type setText:type];
	[cell.task setText:task];
	[cell.date setText:date];
	
	if([[logData valueForKey:@"isError"] boolValue] == YES)
	{
		[cell.type setTextColor:[UIColor redColor]];
		[cell.task setTextColor:[UIColor redColor]];
		[cell.date setTextColor:[UIColor redColor]];
	}
	else
	{
		[cell.type setTextColor:[UIColor blackColor]];
		[cell.task setTextColor:[UIColor blackColor]];
		[cell.date setTextColor:[UIColor blackColor]];
	}

    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

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
	ApiLogs *logData = [self.resultsController objectAtIndexPath:indexPath];
	LogViewController *logViewController = [[LogViewController alloc] initWithNibName:@"LogViewController" bundle:nil];
	[logViewController setLogData:logData];
	[self.navigationController pushViewController:logViewController animated:YES];
	[logViewController release];
}

#pragma mark - fetched result controller delegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self._tableView reloadData];
}

@end
