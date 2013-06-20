//
//  FeedbackViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 7/1/11.
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

#import "FeedbackViewController.h"
#import "SendFeedbackOperation.h"
#import "UtilityClasses.h"

@implementation FeedbackViewController
@synthesize matchData;
@synthesize _tableView;
@synthesize resultsController;
@synthesize listOfItems;
@synthesize checkedAnswerData;
@synthesize declinedMatchNo;

- (id)init
{
	self = [super init];
    if (self)
    {
        // Custom initialization
		appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];

        if(operationQueue == nil)
        {
            operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:4];
            [operationQueue setSuspended:NO];
        }
        
        // register keyboard notifiers
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector (keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
        [dnc addObserver:self selector:@selector (keyboardDidShow:) name: UIKeyboardDidShowNotification object:nil];

        [dnc addObserver:self selector:@selector (keyboardDidHide:) name: UIKeyboardDidHideNotification object:nil];
        [dnc addObserver:self selector:@selector (keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
        
        viewIsLoaded = NO;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		appDelegate = (YongoPalAppDelegate *)[[UIApplication sharedApplication] delegate];

        if(operationQueue == nil)
        {
            operationQueue = [[NSOperationQueue alloc] init];
            [operationQueue setMaxConcurrentOperationCount:2];
        }
        
        // register keyboard notifiers
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector (keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
        [dnc addObserver:self selector:@selector (keyboardDidShow:) name: UIKeyboardDidShowNotification object:nil];
        
        [dnc addObserver:self selector:@selector (keyboardDidHide:) name: UIKeyboardDidHideNotification object:nil];
        [dnc addObserver:self selector:@selector (keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];

        [self.navigationItem setCustomTitle:NSLocalizedString(@"feedbackTitle", nil)];
        
        viewIsLoaded = YES;
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
	[listOfItems release];
    [checkedAnswerData release];

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

	UIImage *cancelImage = [UIImage imageNamed:@"btn_x.png"];
	CGRect cancelFrame = CGRectMake(0, 0, cancelImage.size.width, cancelImage.size.height);
	CUIButton *cancelButton = [[CUIButton alloc] initWithFrame:cancelFrame];
	[cancelButton setBackgroundImage:cancelImage forState:UIControlStateNormal];
	[cancelButton setShowsTouchWhenHighlighted:YES];
	[cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
	[self.navigationItem setLeftBarButtonItem:cancelBarButtonItem];
	[cancelBarButtonItem release];
	[cancelButton release];
	
	UIImage *doneImage = [UIImage imageNamed:@"btn_check.png"];
	CGRect doneFrame = CGRectMake(0, 0, doneImage.size.width, doneImage.size.height);
	CUIButton *doneButton = [[CUIButton alloc] initWithFrame:doneFrame];
	[doneButton setBackgroundImage:doneImage forState:UIControlStateNormal];
	[doneButton setShowsTouchWhenHighlighted:YES];
	[doneButton addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
	[self.navigationItem setRightBarButtonItem:doneBarButtonItem];
	[doneBarButtonItem release];
	[doneButton release];

	keyboardVisible = NO;

	// Initialize the array 
	listOfItems = [[NSMutableArray alloc] init];
	NSMutableArray *group0 = [NSMutableArray arrayWithObjects:[NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], nil];
	NSMutableDictionary *group0Dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:group0, @"checked", nil];
	[listOfItems addObject:group0Dict];
	
	[self updateFeedbackList];
}

- (void)viewDidUnload
{
    [listOfItems release];
	listOfItems = nil;

    [resultsController release];
    resultsController = nil;
    
    [appDelegate saveContext:appDelegate.mainMOC];
    
    [super viewDidUnload];
    
    self._tableView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
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

- (void)updateFeedbackList
{
    resultsController = [self getFeedbackList];
    [resultsController retain];
    
    if([[[resultsController sections] objectAtIndex:0] numberOfObjects] == 0)
    {
        if(viewIsLoaded == YES)
        {
            [appDelegate showLoading];
            [self._tableView setHidden:YES];
        }

        shouldReloadTable = YES;
        [self performSelectorInBackground:@selector(getFeedbackListFromServer) withObject:nil];
    }
    else
    {
        shouldReloadTable = NO;
    }
}

- (NSFetchedResultsController*)getFeedbackList
{
	NSFetchRequest *feedbackListRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"AnswerData" inManagedObjectContext:appDelegate.mainMOC];
	[feedbackListRequest setEntity:entity];
	
	NSSortDescriptor *sortDescripter = [[NSSortDescriptor alloc] initWithKey:@"listOrder" ascending:YES];
	NSArray *sortDescripters = [[NSArray alloc] initWithObjects:sortDescripter, nil];
	[feedbackListRequest setSortDescriptors:sortDescripters];
	[sortDescripters release];
	[sortDescripter release];
	
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] 
															initWithFetchRequest:feedbackListRequest 
															managedObjectContext:appDelegate.mainMOC 
															sectionNameKeyPath:nil
															cacheName:nil];
	[feedbackListRequest release];
	
	fetchedResultsController.delegate = self;
	NSError *error;
	BOOL success = [fetchedResultsController performFetch:&error];
	if(!success)
	{
		NSLog(@"setProgramList error: %@", error);
	}
	return [fetchedResultsController autorelease];
}

- (void)send
{	if(answerChecked == NO)
	{
		NSDictionary *alert = [[NSDictionary alloc] initWithObjectsAndKeys:@"", @"title", NSLocalizedString(@"mustCheckAnswerPrompt", nil), @"message", nil];
		[appDelegate displayAlert:alert];
		[alert release];
	}
	else
	{
		NSMutableDictionary *logParams = [[NSMutableDictionary alloc] init];
        [logParams setValue:[matchData valueForKey:@"matchNo"] forKey:@"matchNo"];
		[logParams setValue:[NSNumber numberWithInt:checkedAnswer] forKey:@"answer"];
		[logParams setValue:otherFeedback.text forKey:@"otherAnswer"];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"sendFeedback" attributes:logParams];
		[logParams release];

        SendFeedbackOperation *sendFeedbackOperation = [[SendFeedbackOperation alloc] initWithMatchData:self.matchData andAnswer:self.checkedAnswerData andOtherFeedback:otherFeedback.text];
        [sendFeedbackOperation setThreadPriority:0.1];
        [operationQueue addOperation:sendFeedbackOperation];
        [sendFeedbackOperation release];

		[self dismissModalViewControllerAnimated:YES];
	}
}

- (void)cancel
{
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"cancelFeedback"];
	[self dismissModalViewControllerAnimated:YES];
}

- (void)getFeedbackListFromServer
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

	NSDictionary *feedbackList = [appDelegate.apiRequest sendServerRequest:@"feedback" withTask:@"getFeedbackList" withData:nil];

    if(feedbackList)
    {
        if([feedbackList count] > 1)
        {
            [self performSelectorOnMainThread:@selector(setFeedbackFromServer:) withObject:feedbackList waitUntilDone:NO];
        }
    }
    
    [pool drain];
}

- (void)setFeedbackFromServer:(NSDictionary*)feedbackList
{
	NSFetchRequest *allFeedbackListData = [[NSFetchRequest alloc] init];
	[allFeedbackListData setEntity:[NSEntityDescription entityForName:@"AnswerData" inManagedObjectContext:appDelegate.mainMOC]];
	[allFeedbackListData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSError *error = nil;
	NSArray *feedbackArray = [appDelegate.mainMOC executeFetchRequest:allFeedbackListData error:&error];
	[allFeedbackListData release];
	for (NSManagedObject *feedback in feedbackArray)
	{
		[appDelegate.mainMOC deleteObject:feedback];
	}
	[appDelegate saveContext:appDelegate.mainMOC];
	
	for(NSDictionary *feedbackData in feedbackList)
	{
		// save in core data
		NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"AnswerData" inManagedObjectContext:appDelegate.mainMOC];
		
		// set answerNo
		NSNumber *answerNo = [NSNumber numberWithInt:[[feedbackData valueForKey:@"answerNo"] intValue]];
		[newManagedObject setValue:answerNo forKey:@"answerNo"];
		
		// set description
		[newManagedObject setValue:[feedbackData valueForKey:@"description"] forKey:@"answerDescription"];
		
		// set listOrder
		NSNumber *listOrder = [NSNumber numberWithInt:[[feedbackData valueForKey:@"listOrder"] intValue]];
		[newManagedObject setValue:listOrder forKey:@"listOrder"];
		
		// save
		[appDelegate saveContext:appDelegate.mainMOC];
	}
    
    if(shouldReloadTable == YES && viewIsLoaded == YES)
    {
        [self._tableView setHidden:NO];
        [appDelegate hideLoading];
    }
}

- (CGFloat)getTextHeight:(NSString *)text
{
	CGFloat result = 0;
	
	if (text)
	{
		// The notes can be of any height
		// This needs to work for both portrait and landscape orientations.
		// Calls to the table view to get the current cell and the rect for the 
		// current row are recursive and call back this method.
		CGSize textSize = {252.0f, 99999.0f};		// width and height of text area
		CGSize size = [text sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
		
		result = size.height;
	}
	
	return result;
}

#pragma mark - keyboard delegate
- (void) keyboardDidShow:(NSNotification *)notif
{
	// If keyboard is visible, return
	if (keyboardVisible)
	{
		return;
    }
	
	// Save the current location so we can restore
	// when keyboard is dismissed
	offset = _tableView.contentOffset;

    if(self._tableView != nil)
    {
        [self._tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
	
	// Keyboard is now visible
	keyboardVisible = YES;
}

- (void)keyboardWillShow:(NSNotification *)notif
{
	if (keyboardVisible)
	{
		return;
    }
	
	// Get the size of the keyboard.
	CGRect keyboardBounds;
    [[notif.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
	CGFloat keyboardHeight = keyboardBounds.size.height;
	
	// Resize the scroll view to make room for the keyboard
	[UIView beginAnimations:@"resizeTable" context:nil];
	[UIView setAnimationDuration:0.25];
	CGRect viewFrame = _tableView.frame;
	viewFrame.size.height -= keyboardHeight;
	_tableView.frame = viewFrame;
	[UIView commitAnimations];
}

- (void)keyboardDidHide:(NSNotification *)notif
{
	// Is the keyboard already shown
	if (!keyboardVisible)
	{
		return;
	}
	
	// Reset the scrollview to previous location
	_tableView.contentOffset = offset;
	
	// Keyboard is no longer visible
	keyboardVisible = NO;
}

- (void)keyboardWillHide:(NSNotification *)notif
{
	if (!keyboardVisible)
	{
		return;
	}
	
	// Reset the frame scroll view to its original value
	[UIView beginAnimations:@"resizeTable" context:nil];
	[UIView setAnimationDuration:0.25];
	_tableView.frame = CGRectMake(0, 0, 320, [UtilityClasses viewHeightWithStatusBar:YES andNavBar:YES]);
	[UIView commitAnimations];
}

#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[[resultsController sections] objectAtIndex:section] numberOfObjects] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *FeedbackCellIdentifier = @"FeedbackCell";
    static NSString *OtherFeedbackCellIdentifier = @"OtherFeedbackCell";
    NSString *CellIdentifier = nil;

    if(indexPath.row != [[[resultsController sections] objectAtIndex:indexPath.section] numberOfObjects])
	{
        CellIdentifier = FeedbackCellIdentifier;
    }
    else
    {
        CellIdentifier = OtherFeedbackCellIdentifier;
    }
    
    FeedbackCell *feedbackCell = feedbackCell = (FeedbackCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if(feedbackCell == nil)
    {
		NSArray *aCell = [[NSBundle mainBundle] loadNibNamed:@"FeedbackCell" owner:nil options:nil];
		if(indexPath.row != [[[resultsController sections] objectAtIndex:indexPath.section] numberOfObjects])
		{
			feedbackCell = [aCell objectAtIndex:0];
		}
		else
		{
			feedbackCell = [aCell objectAtIndex:1];
		}
        
        [feedbackCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [feedbackCell setDelegate:self];
        
        [feedbackCell.checkbox setImage:[UIImage imageNamed:@"radio_off"] forState:UIControlStateNormal];
        [feedbackCell.checkbox setImage:[UIImage imageNamed:@"radio_on"] forState:UIControlStateSelected];
	}

	feedbackCell.row = indexPath.row;
	
	NSDictionary *dictionary = [listOfItems objectAtIndex:indexPath.section];
	NSArray *checkedValues = [dictionary objectForKey:@"checked"];
	
	if([[checkedValues objectAtIndex:indexPath.row] boolValue] == YES)
	{
		[feedbackCell.checkbox setSelected:YES];
	}
	else
	{
		[feedbackCell.checkbox setSelected:NO];
	}

	if(indexPath.row != [[[resultsController sections] objectAtIndex:indexPath.section] numberOfObjects])
	{
		AnswerData *feedbackData = [resultsController objectAtIndexPath:indexPath];
		feedbackCell.feedbackLabel.text = [feedbackData valueForKey:@"answerDescription"];
		
		CGFloat textHeight = [self getTextHeight:[feedbackData valueForKey:@"answerDescription"]];
		CGRect newTextFrame = CGRectMake(feedbackCell.feedbackLabel.frame.origin.x, feedbackCell.feedbackLabel.frame.origin.y, feedbackCell.feedbackLabel.frame.size.width, textHeight);
		[feedbackCell.feedbackLabel setFrame:newTextFrame];
	}
	else
	{
		feedbackCell.feedbackLabel.text = @"Other";
		CGFloat textHeight = [self getTextHeight:@"Other"];
		CGRect newTextFrame = CGRectMake(feedbackCell.feedbackLabel.frame.origin.x, feedbackCell.feedbackLabel.frame.origin.y, feedbackCell.feedbackLabel.frame.size.width, textHeight);
		[feedbackCell.feedbackLabel setFrame:newTextFrame];

		[feedbackCell.shadowView.layer setCornerRadius:5.0];
		[feedbackCell.shadowView.layer setShadowColor:[[UIColor blackColor] CGColor]];
		[feedbackCell.shadowView.layer setShadowOffset:CGSizeMake(1.0f, 1.0f)];
		[feedbackCell.shadowView.layer setShadowOpacity:0.7f];
		[feedbackCell.shadowView.layer setShadowRadius:1.0f];
		
		otherFeedback = feedbackCell.feedbackInput;
		[feedbackCell.feedbackInput setDelegate:self];
		[feedbackCell.feedbackInput.layer setMasksToBounds:YES];
		[feedbackCell.feedbackInput.layer setCornerRadius:4];
		
		if([[checkedValues objectAtIndex:indexPath.row] boolValue] == YES)
		{
			[feedbackCell.feedbackInput setUserInteractionEnabled:YES];
			[feedbackCell.feedbackInput performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.3];
		}
		else
		{
			[feedbackCell.feedbackInput setUserInteractionEnabled:NO];
			[feedbackCell.feedbackInput performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0.3];
		}
	}

	return feedbackCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 50.0f;
	if(indexPath.row != [[[resultsController sections] objectAtIndex:indexPath.section] numberOfObjects])
	{
		AnswerData *feedbackData = [resultsController objectAtIndexPath:indexPath];
		CGFloat textHeight = [self getTextHeight:[feedbackData valueForKey:@"answerDescription"]];
		textHeight += 14.0f;			// top and bottom margin
		result = MAX(textHeight, 50.0f);	// at least one row
	}
	else
	{
		result = 80;
	}
	
	return result;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	[self didCheck:nil atRow:indexPath.row];
}

- (void)didCheck:(id)sender atRow:(int)row
{
	answerChecked = YES;

	NSMutableArray *checkedValues = [[NSMutableArray alloc] init];

	for(int i = 0; i < 5; i++)
	{
		if(i == row)
		{
			if(row != [[[resultsController sections] objectAtIndex:0] numberOfObjects])
			{
				AnswerData *feedbackList = [resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
                self.checkedAnswerData = feedbackList;
				checkedAnswer = [[feedbackList valueForKey:@"answerNo"] intValue];
			}
			else
			{
                self.checkedAnswerData = nil;
				checkedAnswer = 0;
			}

			[checkedValues addObject:[NSNumber numberWithBool:YES]];
		}
		else
		{
			[checkedValues addObject:[NSNumber numberWithBool:NO]];
		}
	}

	NSMutableDictionary *group0Dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:checkedValues, @"checked", nil];
	[checkedValues release];

	[listOfItems replaceObjectAtIndex:0 withObject:group0Dict];
	[_tableView reloadData];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self._tableView reloadData];
}

@end
