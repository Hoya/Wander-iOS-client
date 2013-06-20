//
//  SettingsViewController.m
//  YongoPal
//
//  Created by Jiho Kang on 4/13/11.
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

#import "SettingsViewController.h"
#import "MatchOptionsViewController.h"
#import "NotificationViewController.h"
#import "DebugViewController.h"
#import "IntroViewController.h"
#import "WebViewController.h"

@implementation SettingsViewController
@synthesize listOfItems;
@synthesize _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        [self.navigationItem setCustomTitle:NSLocalizedString(@"settingsTitle", nil)];
        
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:4];
        [operationQueue setSuspended:NO];
    }
    return self;
}

- (void)dealloc
{
    [operationQueue cancelAllOperations];
    [operationQueue release];
	[listOfItems release];
	[_tableView release];
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

	appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];

	// set table background to clear
	_tableView.backgroundColor = [UIColor clearColor];

	// set navi bar button
	UIImage *doneImage = [UIImage imageNamed:@"btn_done.png"];
	CGRect doneFrame = CGRectMake(0, 0, doneImage.size.width, doneImage.size.height);
	CUIButton *doneButton = [[CUIButton alloc] initWithFrame:doneFrame];
	[doneButton setBackgroundImage:doneImage forState:UIControlStateNormal];
	[doneButton setShowsTouchWhenHighlighted:YES];
	[doneButton addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
	[self.navigationItem setRightBarButtonItem:doneBarButtonItem];
	[doneBarButtonItem release];
	[doneButton release];
	
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	// Initialize the array 
	self.listOfItems = [[[NSMutableArray alloc] init] autorelease];

    NSArray *group0 = [[NSArray alloc] initWithObjects:NSLocalizedString(@"editProfileMenu", nil), NSLocalizedString(@"matchOptionsMenu", nil), NSLocalizedString(@"notificationSettingsMenu", nil), NSLocalizedString(@"troubleshootingButton", nil), NSLocalizedString(@"logoutMenu", nil), nil];
	NSDictionary *group0Dict = [[NSDictionary alloc] initWithObjectsAndKeys:group0, @"settings", nil];
	[group0 release];
	[listOfItems addObject:group0Dict];
	[group0Dict release];

    /*
	NSArray *group1 = [[NSArray alloc] initWithObjects:NSLocalizedString(@"editProfileMenu", nil), NSLocalizedString(@"logoutMenu", nil), nil];
	NSDictionary *group1Dict = [[NSDictionary alloc] initWithObjectsAndKeys:group1, @"settings", nil];
	[group1 release];
	[listOfItems addObject:group1Dict];
	[group1Dict release];
     */

	NSArray *group2 = [[NSArray alloc] initWithObjects:NSLocalizedString(@"aboutYongopalMenu", nil), @"Wander Announcements", NSLocalizedString(@"reportBugMenu", nil), NSLocalizedString(@"facebookMenu", nil), NSLocalizedString(@"twitterMenu", nil), NSLocalizedString(@"termsMenu", nil), nil];
    NSDictionary *group2Dict = [[NSDictionary alloc] initWithObjectsAndKeys:group2, @"settings", nil];
	[group2 release];
	[listOfItems addObject:group2Dict];
	[group2Dict release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self._tableView = nil;
    self.listOfItems = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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

- (IBAction)closeSettings
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)logout
{
	// show login screen
	[appDelegate.mainNavController popToRootViewControllerAnimated:NO];
	
	[self dismissModalViewControllerAnimated:YES];
    
    // reset data
	[appDelegate performSelector:@selector(resetAllData)];

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"logout"];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [listOfItems count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSDictionary *dictionary = [listOfItems objectAtIndex:section];
	NSArray *array = [dictionary objectForKey:@"settings"];
	return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Configure the cell...
	NSDictionary *dictionary = [listOfItems objectAtIndex:indexPath.section];
	NSArray *array = [dictionary objectForKey:@"settings"];
	NSString *cellValue = [array objectAtIndex:indexPath.row];
	cell.textLabel.text = cellValue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title = nil;
	switch (section)
	{
		case 0:
			title = NSLocalizedString(@"generalHeader", nil);
			break;
            /*
		case 1:
			title = NSLocalizedString(@"accountHeader", nil);
			break;
             */
		case 1:
			title = NSLocalizedString(@"supportHeader", nil);
			break;
		default:
			break;
	}
	return title;
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

	if(indexPath.section == 0)
	{
        if(indexPath.row == 0)
        {
            ProfileViewController *profileController = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController" bundle:nil];
            [profileController setFirstSignup:NO];
			[self.navigationController pushViewController:profileController animated:YES];
			[profileController release];
        }
        else if(indexPath.row == 1)
		{
			MatchOptionsViewController *optionsController = [[MatchOptionsViewController alloc] initWithNibName:@"MatchOptionsViewController" bundle:nil];
			[self.navigationController pushViewController:optionsController animated:YES];
			[optionsController release];
		}
		else if(indexPath.row == 2)
		{
			NotificationViewController *notificationController = [[NotificationViewController alloc] initWithNibName:@"NotificationViewController" bundle:nil];
			[self.navigationController pushViewController:notificationController animated:YES];
			[notificationController release];
		}
		else if(indexPath.row == 3)
		{
			DebugViewController *debugController = [[DebugViewController alloc] initWithNibName:@"DebugViewController" bundle:nil];
			[self.navigationController pushViewController:debugController animated:YES];
			[debugController release];
		}
        else if(indexPath.row == 4)
        {
            UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:@"Are you sure?"
								  message:nil
								  delegate:self
								  cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
								  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
			[alert setDelegate:self];
            [alert setTag:0];
			[alert show];
			[alert release];
        }
	}
	else if(indexPath.section == 1)
	{
		if(indexPath.row == 0)
		{
			IntroViewController *introController = [[IntroViewController alloc] initWithNibName:@"IntroViewController" bundle:nil];
            [introController setShouldShowProfile:NO];
			[self.navigationController pushViewController:introController animated:YES];
            [self.navigationController setNavigationBarHidden:YES];
			[introController release];
        }
        else if(indexPath.row == 1)
        {
            WebViewController *webView = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
            [webView setUrl:[NSString stringWithFormat:@"http://%@/mobile/announcements", apihost]];
            [webView setNavTitle:@"Announcements"];
            [webView setIsModalView:NO];
            [self.navigationController pushViewController:webView animated:YES];
            [webView release];
        }
		else if(indexPath.row == 2)
		{            
			if([MFMailComposeViewController canSendMail])
			{
				MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
				mailController.mailComposeDelegate = self;
                mailController.navigationBar.tintColor = [UIColor blackColor];

				UIBarButtonItem *sendBtn = mailController.navigationBar.topItem.rightBarButtonItem;
				UIBarButtonItem *cancelBtn = mailController.navigationBar.topItem.leftBarButtonItem;
				id mailTarget = sendBtn.target;
                
				UIImage *cancelImage = [UIImage imageNamed:@"btn_x.png"];
				CGRect cancelFrame = CGRectMake(0, 0, cancelImage.size.width, cancelImage.size.height);
				UIButton *cancelButton = [[UIButton alloc] initWithFrame:cancelFrame];
				[cancelButton setBackgroundImage:cancelImage forState:UIControlStateNormal];
				[cancelButton setShowsTouchWhenHighlighted:YES];
				[cancelButton addTarget:mailTarget action:cancelBtn.action forControlEvents:UIControlEventTouchUpInside];
				UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
				[mailController.navigationBar.topItem setLeftBarButtonItem:cancelBarButtonItem];
				[cancelBarButtonItem release];
				[cancelButton release];
#warning the email address needs to be filled in
				[mailController setToRecipients:[NSArray arrayWithObject:@""]];
				[mailController setSubject:NSLocalizedString(@"foundProblemTitle", nil)];
                
				NSString *emailBody;
				emailBody = NSLocalizedString(@"reportBugEmailText", nil);
				[mailController setMessageBody:emailBody isHTML:YES];
                [self presentModalViewController:mailController animated:YES];
				[mailController release];
			}
			else
			{
				NSDictionary *mailAlert = [[NSDictionary alloc] initWithObjectsAndKeys:@"Sorry", @"title", @"Email is not setup on this device", @"message", nil];
				[appDelegate displayAlert:mailAlert];
				[mailAlert release];
			}
		}
        else if(indexPath.row == 3)
        {
            WebViewController *webView = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
            [webView setUrl:[NSString stringWithFormat:@"http://%@/facebook.php", apihost]];
            [webView setNavTitle:NSLocalizedString(@"facebookMenu", nil)];
            [webView setIsModalView:NO];
            [self.navigationController pushViewController:webView animated:YES];
            [webView release];
        }
        else if(indexPath.row == 4)
        {
            WebViewController *webView = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
            [webView setUrl:[NSString stringWithFormat:@"http://%@/twitter.php", apihost]];
            [webView setNavTitle:NSLocalizedString(@"twitterMenu", nil)];
            [webView setIsModalView:NO];
            [self.navigationController pushViewController:webView animated:YES];
            [webView release];
        }
        else if(indexPath.row == 5)
		{
            WebViewController *webView = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
            [webView setUrl:[NSString stringWithFormat:@"http://%@/terms", apihost]];
            [webView setNavTitle:@"Terms & Privacy Policy"];
            [webView setIsModalView:NO];
            [self.navigationController pushViewController:webView animated:YES];
            [webView release];
        }
	}
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == 0)
    {
        if(buttonIndex == 1)
		{
            [self performSelector:@selector(logout)];
        }
    }
}

# pragma mark - MFMailComposeViewController delegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	switch (result)
	{
		case MFMailComposeResultCancelled:
            if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"Mail Result Cancelled");
            }
			break;
		case MFMailComposeResultSaved:
            if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"Mail Result: saved");
            }
			break;
		case MFMailComposeResultSent:
            if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"Mail Result: sent");
            }
			break;
		case MFMailComposeResultFailed:
            if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"Mail Result: failed");
            }
			NSDictionary *mailAlert = [[NSDictionary alloc] initWithObjectsAndKeys:@"Sorry", @"title", @"Email delivery failed", @"message", nil];
			[appDelegate displayAlert:mailAlert];
			[mailAlert release];
			break;
		default:
            if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"Mail Result: not sent");
            }
			break;
	}
    
	[self dismissModalViewControllerAnimated:YES];
}

@end
