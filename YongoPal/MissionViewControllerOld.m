//
//  MissionViewControllerOld.m
//  YongoPal
//
//  Created by Jiho Kang on 5/17/11.
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

#import "MissionViewControllerOld.h"
#import "UtilityClasses.h"

@implementation MissionViewControllerOld
@synthesize matchData;
@synthesize delegate;
@synthesize resultsController;
@synthesize _tableView;
@synthesize viewTitle;
@synthesize selectedMission;
@synthesize todayUTC;
@synthesize highlightView;
@synthesize matchNo;
@synthesize firstRun;
@synthesize selectedMissionNo;

- (id)init
{
    self = [super init];
    if (self)
	{
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        if(self.todayUTC == nil) self.todayUTC = [UtilityClasses currentUTCDate];

        if(operationQueue == nil)
        {
            operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:4];
            [operationQueue setSuspended:NO];
        }
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(showChatView:) name:@"shouldPopToChatView" object:nil];
        [dnc addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        if(self.todayUTC == nil) self.todayUTC = [UtilityClasses currentUTCDate];
        
        if(operationQueue == nil)
        {
            operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:4];
            [operationQueue setSuspended:NO];
        }
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(showChatView:) name:@"shouldPopToChatView" object:nil];
        [dnc addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [matchData release];
    [operationQueue cancelAllOperations];
    [operationQueue release];
    [_tableView release];
    [resultsController release];
	[viewTitle release];
	[selectedMission release];
	[todayUTC release];
    [highlightView release];

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

    // Custom initialization
    [self.navigationItem setCustomTitle:viewTitle];

	// set navigation buttons
	UIImage *backImage = [UIImage imageNamed:@"btn_x.png"];
	CGRect backFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
	CUIButton *backButton = [[CUIButton alloc] initWithFrame:backFrame];
	[backButton setBackgroundImage:backImage forState:UIControlStateNormal];
	[backButton setShowsTouchWhenHighlighted:YES];
	[backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
	[self.navigationItem setLeftBarButtonItem:backBarButtonItem];
	[backBarButtonItem release];
	[backButton release];

	[self getMissions:matchNo];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self._tableView setDelegate:nil];
    self._tableView = nil;
    self.highlightView = nil;
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
    currentOrientation = [[UIDevice currentDevice] orientation];
    
    if(UIDeviceOrientationIsLandscape(currentOrientation))
    {
        CGRect tableFrame = self._tableView.frame;
        [UIView beginAnimations:@"hideLocalTime" context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [self._tableView setFrame:CGRectMake(tableFrame.origin.x, 0, tableFrame.size.width, tableFrame.size.height+10)];
        [UIView commitAnimations];
        
        // resize the navbar
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, [UtilityClasses viewHeightWithStatusBar:NO andNavBar:NO], 32)];
        
        // remove nav bar captions
        [[self.navigationController navigationBar] removeCaptions];
        
        return YES;
    }
    else if(UIDeviceOrientationIsPortrait(currentOrientation))
    {
        CGRect tableFrame = self._tableView.frame;
        [UIView beginAnimations:@"showLocalTime" context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [self._tableView setFrame:CGRectMake(tableFrame.origin.x, 10, tableFrame.size.width, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES] - 10)];
        [UIView commitAnimations];
        
        // resize the navbar
        [[self.navigationController navigationBar] resizeBGLayer:CGRectMake(0, 0, 320, 54)];
        [[self.navigationController navigationBar] performSelectorOnMainThread:@selector(setCaption:) withObject:NSLocalizedString(@"missionCaption", nil) waitUntilDone:NO];
        
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
    if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        // remove nav bar captions 
        [[self.navigationController navigationBar] performSelectorOnMainThread:@selector(removeCaptions) withObject:nil waitUntilDone:NO];
    }
    else
    {   
        // restore nav bar captions
        [[self.navigationController navigationBar] performSelectorOnMainThread:@selector(setCaption:) withObject:NSLocalizedString(@"missionCaption", nil) waitUntilDone:NO];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self._tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    // resize the navbar
    [self orientationChanged:nil];

	// check for new missions
	[self checkNewMissions];

	if([self hasNewMissions] == YES)
	{
		firstRun = YES;
	}
	else
	{
		firstRun = NO;
	}
    
    firstRun = NO;

	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"missionViewDidAppear"];
    
    if([[appDelegate.prefs valueForKey:@"hasNewMissions"] boolValue] == YES)
    {
        UIApplication *yongopalApp = [UIApplication sharedApplication];
        [appDelegate setApplicationBadgeNumber:[NSNumber numberWithInt:yongopalApp.applicationIconBadgeNumber-1]];
        [appDelegate.prefs setInteger:0 forKey:@"newMissionAlert"];
        [appDelegate.prefs setValue:[NSNumber numberWithBool:NO] forKey:@"hasNewMissions"];
        [appDelegate.prefs synchronize];
    }

    if(self.selectedMissionNo != nil)
    {
        NSArray *tempArray = [[NSArray alloc] initWithArray:self.resultsController.fetchedObjects];
        int row = 0;
        for(MissionData *mission in tempArray)
        {
            if([self.selectedMissionNo isEqualToNumber:[mission valueForKey:@"missionNo"]])
            {
                [self highlightMission:[NSIndexPath indexPathForRow:row inSection:0]];
                break;
            }
            row = row + 1;
        }
        [tempArray release];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)goBack
{
    currentOrientation = [[UIDevice currentDevice] orientation];

	// resize navigation bar and table view
	CATransition *modalAnimation = [CATransition animation];
	[modalAnimation setDuration:0.3];
	[modalAnimation setType:kCATransitionReveal];

	if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        [modalAnimation setSubtype:kCATransitionFromLeft];
    }
    else if(self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        [modalAnimation setSubtype:kCATransitionFromRight];
    }
    else
    {
        [modalAnimation setSubtype:kCATransitionFromBottom];
    }

	[modalAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
	[modalAnimation setDelegate:self];
	[self.navigationController.view.layer addAnimation:modalAnimation forKey:nil];
	[self.navigationController popViewControllerAnimated:NO];
}

- (bool)hasNewMissions
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setIncludesPropertyValues:NO];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"MissionData" inManagedObjectContext:appDelegate.mainMOC];
	[request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = %d and date = %@", matchNo, todayUTC];
	[request setPredicate:predicate];
	
	NSError *error = nil;
	int missionCount = [appDelegate.mainMOC countForFetchRequest:request error:&error];
	[request release];

	if(missionCount == 0)
	{
        [appDelegate.prefs setValue:[NSNumber numberWithBool:YES] forKey:@"hasNewMissions"];
        [appDelegate.prefs synchronize];
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)checkNewMissions
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setIncludesPropertyValues:NO];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"MissionData" inManagedObjectContext:appDelegate.mainMOC];
	[request setEntity:entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = %d and date = %@", matchNo, todayUTC];
	[request setPredicate:predicate];

	NSError *error = nil;
	NSUInteger count = [appDelegate.mainMOC countForFetchRequest:request error:&error];
	[request release];

	if(count == 0)
	{
        NSInvocationOperation *getMissionsOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(getMissionsFromServer) object:nil];
        [operationQueue addOperation:getMissionsOperation];
        [getMissionsOperation release];
	}
}

- (void)getMissions:(int)matchNumber;
{
	NSFetchRequest *missionDataRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"MissionData" inManagedObjectContext:appDelegate.mainMOC];
	[missionDataRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo = %d", matchNo]];
	[missionDataRequest setPredicate:predicate];
	
	NSSortDescriptor *sortDescripter = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	NSSortDescriptor *sortDescripter2 = [[NSSortDescriptor alloc] initWithKey:@"check" ascending:YES];
	NSArray *sortDescripters = [[NSArray alloc] initWithObjects:sortDescripter, sortDescripter2, nil];
	[missionDataRequest setSortDescriptors:sortDescripters];
	[sortDescripters release];
	[sortDescripter release];
	[sortDescripter2 release];

	[missionDataRequest setFetchLimit:35];
	
    [NSFetchedResultsController deleteCacheWithName:[NSString stringWithFormat:@"%d_mission.cache", matchNumber]];
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] 
															initWithFetchRequest:missionDataRequest 
															managedObjectContext:appDelegate.mainMOC 
															sectionNameKeyPath:@"date"
															cacheName:[NSString stringWithFormat:@"%d_mission.cache", matchNumber]];
	[missionDataRequest release];

	[fetchedResultsController setDelegate:self];
	NSError *error;
	BOOL success = [fetchedResultsController performFetch:&error];
	if(!success)
	{
		NSLog(@"setMissionList error: %@", error);
	}
	self.resultsController = fetchedResultsController;
    [fetchedResultsController release];
}

- (void)getMissionsFromServer
{
    if([appDelegate.networkStatus boolValue] == NO)
	{
		return;
	}

    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

	NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[requestData setValue:memberNoString forKey:@"memberNo"];
	[requestData setValue:[NSNumber numberWithInt:matchNo] forKey:@"matchNo"];

	NSDictionary *missions = [appDelegate.apiRequest sendServerRequest:@"mission" withTask:@"getNewMissions" withData:requestData];
	[requestData release];

    if(missions)
    {
        if([missions count] > 0)
        {
            for(NSDictionary *missionData in missions)
            {
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                NSEntityDescription *entity = [NSEntityDescription entityForName:@"MissionData" inManagedObjectContext:threadContext];
                [request setEntity:entity];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo == %d AND missionNo == %d", matchNo, [[missionData valueForKey:@"missionNo"] intValue]]];
                [request setPredicate:predicate];
                
                NSError *error = nil;
                NSUInteger count = [threadContext countForFetchRequest:request error:&error];
                [request release];
                
                if(count == 0)
                {
                    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"MissionData" inManagedObjectContext:threadContext];
                    
                    // set matchNo
                    [newManagedObject setValue:[NSNumber numberWithInt:matchNo] forKey:@"matchNo"];
                    
                    // set missionNo
                    [newManagedObject setValue:[NSNumber numberWithInt:[[missionData valueForKey:@"missionNo"] intValue]] forKey:@"missionNo"];
                    
                    // set mission description
                    [newManagedObject setValue:[missionData valueForKey:@"description"] forKey:@"mission"];
                    
                    // set date
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd"];
                    NSDate *date = [formatter dateFromString:[missionData valueForKey:@"date"]];
                    
                    [newManagedObject setValue:date forKey:@"date"];
                    [formatter release];
                    
                    // set check
                    if([missionData valueForKey:@"checked"] != [NSNull null])
                    {
                        if([[missionData valueForKey:@"checked"] isEqual: @"Y"])
                        {
                            [newManagedObject setValue:[NSNumber numberWithBool:YES] forKey:@"check"];
                        }
                        else if([[missionData valueForKey:@"checked"] isEqual: @"N"])
                        {
                            [newManagedObject setValue:[NSNumber numberWithBool:NO] forKey:@"check"];
                        }
                    }
                    
                    // set match data relationship
                    NSManagedObject *relatedMatchData = [threadContext objectWithID:[matchData objectID]];
                    [newManagedObject setValue:relatedMatchData forKey:@"matchData"];
                }
            }
            
            // save
            [appDelegate saveContext:threadContext];
        }
    }
}

- (CGFloat)getTextHeight:(NSIndexPath *)indexPath forWidth:(float)width
{
	CGFloat result = 0;

	MissionData *missionData = [resultsController objectAtIndexPath:indexPath];
	NSString *text = [missionData valueForKey:@"mission"];
	
	if (text)
	{
		// The notes can be of any height
		// This needs to work for both portrait and landscape orientations.
		// Calls to the table view to get the current cell and the rect for the 
		// current row are recursive and call back this method.
		CGSize textSize = {width, 99999.0f};		// width and height of text area
		CGSize size = [text sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
		result = size.height;
	}
	
	return result;
}

- (void)saveImageToCameraRoll:(UIImage*)image
{
	UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[resultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MissionCell";
    
    MissionCell *cell = (MissionCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) {
		NSArray *aCell = [[NSBundle mainBundle] loadNibNamed:@"MissionCell" owner:nil options:nil];
		cell = [aCell objectAtIndex:0];
	}

	MissionData *missionData = [resultsController objectAtIndexPath:indexPath];

    // Configure the cell...
	CGFloat textHeight = [self getTextHeight:indexPath forWidth:(tableView.frame.size.width - 75)];
	if(textHeight > 56)
	{
		CGRect newMissionFrame = cell.missionText.frame;
		newMissionFrame.size.height = textHeight;
		cell.missionText.frame = newMissionFrame;
	}

	if([[missionData valueForKey:@"check"] boolValue] == YES)
	{
		[cell.checkIcon setImage:[UIImage imageNamed:@"ico_missioncheck"]];
		[cell.missionText setTextColor:[UIColor colorWithWhite:0.6 alpha:1.0]];
		[cell.container setBackgroundColor:[UIColor clearColor]];
		
		[cell.container.layer setMasksToBounds:YES];
		[cell.container.layer setCornerRadius:10];
		[cell.container.layer setBorderColor: [[UIColor colorWithWhite:0.9 alpha:1.0] CGColor]];
		[cell.container.layer setBorderWidth: 1.0];
	}
	else
	{
		[cell.missionText setTextColor:[UIColor colorWithWhite:0.13 alpha:1.0]];
		[cell.container setBackgroundColor:[UIColor whiteColor]];

		// Convert rawDateStr string to NSDate...
		NSDate* sourceDate = [missionData valueForKey:@"date"];
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd"];
		NSString *missionDate = [formatter stringFromDate:sourceDate];
		[formatter release];
		
		NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
		[formatter2 setDateFormat:@"yyyy-MM-dd"];
		NSString *stringUTC = [formatter2 stringFromDate:todayUTC];
		[formatter2 release];

		if([missionDate isEqualToString:stringUTC])
		{
			[cell.checkIcon setImage:[UIImage imageNamed:@"ico_missionblue"]];
		}
		else
		{
			[cell.checkIcon setImage:[UIImage imageNamed:@"ico_missionblack"]];
		}
		
		[cell.container.layer setMasksToBounds:YES];
		[cell.container.layer setCornerRadius:10];
		[cell.container.layer setBorderColor: [[UIColor colorWithWhite:0.77 alpha:1.0] CGColor]];
		[cell.container.layer setBorderWidth: 1.0];
	}

	UITableViewCell *selectedView = [[UITableViewCell alloc] initWithFrame:CGRectZero];
	selectedView.backgroundColor = [UIColor clearColor];
	cell.selectedBackgroundView = selectedView;
	[selectedView release];

	cell.missionText.text = [missionData valueForKey:@"mission"];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 70.0f;
	CGFloat textHeight = [self getTextHeight:indexPath forWidth:(tableView.frame.size.width - 75)];
	textHeight += 14.0f; // top and bottom margin

	if(textHeight > 70)
	{
		result = textHeight; // at least one row
	}

	return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	NSString *rawDateStr = [[[resultsController sections] objectAtIndex:section] name];
	UIImageView *headerImage = [[UIImageView alloc] initWithFrame:CGRectMake((self._tableView.frame.size.width - 90), 3, 90, 25)];
    [headerImage setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];

	// Convert rawDateStr string to NSDate...
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"];
	NSDate* sourceDate = [formatter dateFromString:rawDateStr];
	[formatter setDateFormat:@"yyyy-MM-dd"];
	NSString *missionDate = [formatter stringFromDate:sourceDate];
	[formatter release];

	NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
	[formatter2 setDateFormat:@"yyyy-MM-dd"];
	NSString *stringUTC = [formatter2 stringFromDate:todayUTC];
	[formatter2 release];
	
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self._tableView.frame.size.width, 31)] autorelease];
    [header setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth];

	if([missionDate isEqualToString:stringUTC])
	{
		[headerImage setImage:[UIImage imageNamed:@"flag_today.png"]];

		if(firstRun == YES)
		{
			[header setFrame:CGRectMake(0, 0, 320, 111)];
			[headerImage setFrame:CGRectMake(230, 73, 90, 25)];
			UIImageView *newMissionHeader = [[UIImageView alloc] initWithFrame:CGRectMake(15, 20, 290, 40)];
			[newMissionHeader setImage:[UIImage imageNamed:@"cm_missions.png"]];
			[header addSubview:newMissionHeader];
			[newMissionHeader release];
		}
	}
	else
	{
		[headerImage setImage:[UIImage imageNamed:@"flag_older.png"]];
	}

	[header setBackgroundColor:[UIColor clearColor]];
	[header addSubview:headerImage];
	[headerImage release];

	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(firstRun == YES && section == 0)
	{
		return 101;
	}
	else
	{
		return 31;
	}
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self unhighlightMission];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	self.selectedMission = indexPath;
    MissionData *missionData = [resultsController objectAtIndexPath:indexPath];
	
	UIActionSheet *sheet;
    
    if([[missionData valueForKey:@"check"] boolValue] == YES)
    {
        sheet = [[UIActionSheet alloc]
				 initWithTitle:nil
				 delegate:self
				 cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
				 destructiveButtonTitle:nil
				 otherButtonTitles: NSLocalizedString(@"markIncompleteButton", nil), nil];
        [sheet setTag:1];
    }
	else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		sheet = [[UIActionSheet alloc]
				 initWithTitle:nil
				 delegate:self
				 cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
				 destructiveButtonTitle:nil
				 otherButtonTitles:NSLocalizedString(@"takePhotoButton", nil), NSLocalizedString(@"choosePhotoButton", nil), NSLocalizedString(@"markCompleteButton", nil), nil];
        [sheet setTag:0];
	}
	else
	{
		sheet = [[UIActionSheet alloc]
				 initWithTitle:nil
				 delegate:self
				 cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
				 destructiveButtonTitle:nil
				 otherButtonTitles:NSLocalizedString(@"choosePhotoButton", nil), NSLocalizedString(@"markCompleteButton", nil), nil];
        [sheet setTag:0];
	}
	[sheet showInView:self.view];
	[sheet release];
}

#pragma mark - fetched result controller delegate
-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[_tableView reloadData];
}

#pragma mark - action sheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == 1)
    {
        if(buttonIndex == 0)
        {
            MissionData *missionData = [resultsController objectAtIndexPath:selectedMission];
            [missionData setValue:[NSNumber numberWithBool:NO] forKey:@"check"];

            [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"markMissionIncomplete"];

            NSInvocationOperation *logOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(logMission:) object:missionData];
            [operationQueue addOperation:logOperation];
            [logOperation release];
            
            [appDelegate saveContext:appDelegate.mainMOC];
        }
    }
    else
    {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            if(buttonIndex == 0)
            {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentModalViewController:picker animated:YES];
                [picker release];
            }
            else if(buttonIndex == 1 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                [self presentModalViewController:picker animated:YES];
                [picker release];
            }
            else if(buttonIndex == 2)
            {
                MissionData *missionData = [resultsController objectAtIndexPath:selectedMission];
                [missionData setValue:[NSNumber numberWithBool:YES] forKey:@"check"];

                [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"markMissionComplete"];
                
                NSInvocationOperation *logOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(logMission:) object:missionData];
                [operationQueue addOperation:logOperation];
                [logOperation release];
                
                [appDelegate saveContext:appDelegate.mainMOC];
            }
        }
        else
        {
            if(buttonIndex == 0 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                [self presentModalViewController:picker animated:YES];
                [picker release];
            }
            else if(buttonIndex == 1)
            {
                MissionData *missionData = [resultsController objectAtIndexPath:selectedMission];
                [missionData setValue:[NSNumber numberWithBool:YES] forKey:@"check"];

                [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"markMissionComplete"];

                NSInvocationOperation *logOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(logMission:) object:missionData];
                [operationQueue addOperation:logOperation];
                [logOperation release];
                
                [appDelegate saveContext:appDelegate.mainMOC];
            }
        }
    }
}

#pragma mark - image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	UIImage *originalImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    MissionData *selectedMissionData = [self.resultsController objectAtIndexPath:self.selectedMission];
	
	if([info objectForKey:@"UIImagePickerControllerReferenceURL"] && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
        [appDelegate showLoading];

		NSDictionary *pushData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  picker, @"picker",
                                  originalImage, @"image",
                                  [NSNumber numberWithBool:NO], @"shouldSaveToCameraRoll",
                                  [NSNumber numberWithInt:UIImagePickerControllerSourceTypePhotoLibrary], @"sourceType",
                                  [selectedMissionData valueForKey:@"missionNo"], @"missionNo",
                                  [selectedMissionData valueForKey:@"mission"], @"mission",
                                  nil];
        
        [self performSelector:@selector(pushShareControllerWithData:) withObject:pushData afterDelay:0.0];
	}
	else
	{
        [appDelegate showLoading];

        NSDictionary *pushData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  picker, @"picker",
                                  originalImage, @"image",
                                  [NSNumber numberWithBool:YES], @"shouldSaveToCameraRoll",
                                  [NSNumber numberWithInt:UIImagePickerControllerSourceTypeCamera], @"sourceType",
                                  [selectedMissionData valueForKey:@"missionNo"], @"missionNo",
                                  [selectedMissionData valueForKey:@"mission"], @"mission",
                                  nil];

        [self performSelector:@selector(pushShareControllerWithData:) withObject:pushData afterDelay:0.0];
	}
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
	// Was there an error?
	if (error != NULL)
	{
		// Show error message...
		NSLog(@"error saving to camera roll: %@", error);
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[picker dismissModalViewControllerAnimated:YES];
}

- (void)pushShareControllerWithData:(NSDictionary*)data
{
    if(delegate != nil)
    {
        [delegate pushShareControllerWithData:data];
    }
}

- (void)logMission:(MissionData*)missionData
{
    NSNumber *missionNo = [missionData valueForKey:@"missionNo"];
    NSString *checkValue = nil;
    if([[missionData valueForKey:@"check"] boolValue] == YES)
    {
        checkValue = @"Y";
    }
    else
    {
        checkValue = @"N";
    }

    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[requestData setValue:memberNoString forKey:@"memberNo"];
	[requestData setValue:[NSNumber numberWithInt:matchNo] forKey:@"matchNo"];
    [requestData setValue:missionNo forKey:@"missionNo"];
    [requestData setValue:checkValue forKey:@"checked"];
    [appDelegate.apiRequest sendServerRequest:@"mission" withTask:@"checkMission" withData:requestData];
    [requestData release];
}

- (void)highlightMission:(NSIndexPath*)indexPath
{
    [self unhighlightMission];

    if(self._tableView != nil && indexPath.row < [self._tableView numberOfRowsInSection:0])
    {
        [self._tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self._tableView setScrollEnabled:NO];

        CGRect highlightRect = [self._tableView rectForRowAtIndexPath:indexPath];
        
        CALayer *highlightLayer = [CALayer new];
        [highlightLayer setFrame:CGRectMake(0, 10, 320, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES] - 10)];
        [highlightLayer setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:1.0].CGColor];
        [highlightLayer setName:@"highlightLayer"];
        
        float topBound = (highlightRect.origin.y) / [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES] - 10;
        float bottomBound = (highlightRect.origin.y + highlightRect.size.height) / [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES] - 10;
        
        CAGradientLayer *maskLayer = [CAGradientLayer layer];
        
        CGColorRef outerColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
        CGColorRef innerColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
        
        maskLayer.colors = [NSArray arrayWithObjects:(id)innerColor, (id)innerColor, (id)outerColor, (id)outerColor, (id)innerColor, (id)innerColor, nil];
        maskLayer.locations = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:0.0],
                               [NSNumber numberWithFloat:topBound - 0.1],
                               [NSNumber numberWithFloat:topBound + 0.05],
                               [NSNumber numberWithFloat:bottomBound - 0.05],
                               [NSNumber numberWithFloat:bottomBound + 0.1],
                               [NSNumber numberWithFloat:1.0], nil];
        
        maskLayer.bounds = CGRectMake(0, 10, 320, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES] - 10);
        maskLayer.anchorPoint = CGPointZero;
        
        highlightLayer.mask = maskLayer;
        
        CATransition *fadeAnimation = [CATransition animation];
        [fadeAnimation setDuration:0.3];
        [fadeAnimation setType:kCATransitionFade];
        [fadeAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [highlightLayer addAnimation:fadeAnimation forKey:nil];

        [self._tableView.layer.superlayer addSublayer:highlightLayer];
        [highlightLayer release];
    }
}

- (void)unhighlightMission
{
    [self._tableView setScrollEnabled:YES];
    for(CALayer *sublayer in self._tableView.layer.superlayer.sublayers)
    {
        if([sublayer.name isEqualToString:@"highlightLayer"])
        {
            CATransition *fadeAnimation = [CATransition animation];
            [fadeAnimation setDuration:0.3];
            [fadeAnimation setType:kCATransitionFade];
            [fadeAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            [sublayer addAnimation:fadeAnimation forKey:nil];
            [sublayer removeFromSuperlayer];
            break;
        }
    }
}

#pragma mark - image picker navigation controller delegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
}

- (void)showChatView:(NSNotification*)noif
{
    [self._tableView setDelegate:nil];
    self._tableView = nil;
    
    MissionData *missionData = [resultsController objectAtIndexPath:selectedMission];
	[missionData setValue:[NSNumber numberWithBool:YES] forKey:@"check"];

    [appDelegate saveContext:appDelegate.mainMOC];

    [self.navigationController popViewControllerAnimated:NO];
}

@end
