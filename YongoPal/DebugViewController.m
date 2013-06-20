//
//  DebugViewController.m
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

#import "DebugViewController.h"
#import "DebugSettingsViewController.h"
#import "LogListController.h"
#import "SelectServerController.h"
#import "UnlockViewController.h"

#import "ASIFormDataRequest.h"
#import "UpdateMatchListOperation.h"
#import "UtilityClasses.h"

#import "ChatData.h"

@implementation DebugViewController
@synthesize listOfItems;
@synthesize _tableView;
@synthesize loadingView;
@synthesize buildLabel;
@synthesize spinner;
@synthesize progressView;
@synthesize progressView2;
@synthesize loadingLabel;
@synthesize apiRequest;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        self.apiRequest = [[[APIRequest alloc] init] autorelease];
        [self.apiRequest setDelegate:self];
        
        // set operation stuff
        receiveOperationQueue = [[NSOperationQueue alloc] init];
        [receiveOperationQueue setMaxConcurrentOperationCount:1];
        [receiveOperationQueue setSuspended:NO];
        
        downloadPool = [[NSMutableArray alloc] init];

        [self.navigationItem setCustomTitle:@"Troubleshooting"];
    }
    return self;
}

- (void)dealloc
{
	[listOfItems release];
	[_tableView release];
    [loadingView release];
    [buildLabel release];
    [spinner release];
    [progressView release];
    [progressView2 release];
    [loadingLabel release];
    
    [apiRequest setDelegate:nil];
    [apiRequest release];

    [receiveOperationQueue cancelAllOperations];
    [receiveOperationQueue release];
    
    [downloadPool release];

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

    // set table background to clear
	self._tableView.backgroundColor = [UIColor clearColor];
    
    // set build number
    [self.buildLabel setText:[NSString stringWithFormat:@"Wander, build %d", [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] intValue]]];
	
	// Initialize the array 
	self.listOfItems = [[[NSMutableArray alloc] init] autorelease];

    NSArray *group0 = nil;
    if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
    {
        group0 = [NSArray arrayWithObjects:@"Debug", @"Logs", @"Unlock Features", NSLocalizedString(@"reRegisterDeviceButton", nil), NSLocalizedString(@"restoreAppDataButton", nil), @"Clear Device Chat Data", @"Clear Device Guide List", @"Select Server", @"Clear Server Match Data", @"Clear All Server Data", nil];
    }
    else
    {
        group0 = [NSArray arrayWithObjects:@"Debug", @"Logs", @"Unlock Features", nil];
    }
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

    self.listOfItems = nil;
	self._tableView = nil;
    self.loadingView = nil;
    self.buildLabel = nil;
    self.spinner = nil;
    self.progressView = nil;
    self.progressView2 = nil;
    self.loadingLabel = nil;
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

- (void)checkAccessCode:(NSString*)code
{
    int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
	NSMutableDictionary *memberData = [[NSMutableDictionary alloc] init];
	[memberData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
	NSDictionary *results = [appDelegate.apiRequest sendServerRequest:@"member" withTask:@"getAccessCode" withData:memberData];
	[memberData release];

    if(results)
    {
        if([code isEqualToString:[results valueForKey:@"accessCode"]])
        {
            [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:YES];
            [self performSelectorOnMainThread:@selector(pushToUnlockView) withObject:nil waitUntilDone:NO];
        }
        else
        {
            [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:YES];
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Oops"
                                  message:@"The access code that you provided is incorrect"
                                  delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
            [alert setTag:99];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            [alert release];
        }
    }
}

- (void)pushToUnlockView
{
    UnlockViewController *unlockController = [[UnlockViewController alloc] initWithNibName:@"UnlockViewController" bundle:nil];
    [self.navigationController pushViewController:unlockController animated:YES];
    [unlockController release];
}

- (void)clearChatData
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    NSError *error;
    NSFetchRequest *allTranslationData = [[NSFetchRequest alloc] init];
	[allTranslationData setEntity:[NSEntityDescription entityForName:@"TranslationData" inManagedObjectContext:threadContext]];
	[allTranslationData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *translationArray = [threadContext executeFetchRequest:allTranslationData error:&error];
	[allTranslationData release];
	for (NSManagedObject *translation in translationArray)
	{
		[threadContext deleteObject:translation];
	}
    
    NSFetchRequest *allImageData = [[NSFetchRequest alloc] init];
	[allImageData setEntity:[NSEntityDescription entityForName:@"ImageData" inManagedObjectContext:threadContext]];
	[allImageData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *imageArray = [threadContext executeFetchRequest:allImageData error:&error];
	[allImageData release];
	for (NSManagedObject *image in imageArray)
	{
		[threadContext deleteObject:image];
	}
    
    NSFetchRequest *allChatData = [[NSFetchRequest alloc] init];
	[allChatData setEntity:[NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:threadContext]];
	[allChatData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *chatArray = [threadContext executeFetchRequest:allChatData error:&error];
	[allChatData release];
	for (NSManagedObject *chat in chatArray)
	{
		[threadContext deleteObject:chat];
	}

    [appDelegate saveContext:threadContext];
    [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];

    [pool drain];
}

- (void)clearMatchData
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];

    NSError *error;
    NSFetchRequest *allTranslationData = [[NSFetchRequest alloc] init];
	[allTranslationData setEntity:[NSEntityDescription entityForName:@"TranslationData" inManagedObjectContext:threadContext]];
	[allTranslationData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *translationArray = [threadContext executeFetchRequest:allTranslationData error:&error];
	[allTranslationData release];
	for (NSManagedObject *translation in translationArray)
	{
		[threadContext deleteObject:translation];
	}
    
    NSFetchRequest *allImageData = [[NSFetchRequest alloc] init];
	[allImageData setEntity:[NSEntityDescription entityForName:@"ImageData" inManagedObjectContext:threadContext]];
	[allImageData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *imageArray = [threadContext executeFetchRequest:allImageData error:&error];
	[allImageData release];
	for (NSManagedObject *image in imageArray)
	{
		[threadContext deleteObject:image];
	}
    
    NSFetchRequest *allChatData = [[NSFetchRequest alloc] init];
	[allChatData setEntity:[NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:threadContext]];
	[allChatData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *chatArray = [threadContext executeFetchRequest:allChatData error:&error];
	[allChatData release];
	for (NSManagedObject *chat in chatArray)
	{
		[threadContext deleteObject:chat];
	}
    
    NSFetchRequest *allMissionData = [[NSFetchRequest alloc] init];
	[allMissionData setEntity:[NSEntityDescription entityForName:@"MissionData" inManagedObjectContext:threadContext]];
	[allMissionData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *missionArray = [threadContext executeFetchRequest:allMissionData error:&error];
	[allMissionData release];
	for (NSManagedObject *mission in missionArray)
	{
		[threadContext deleteObject:mission];
	}
    
    NSFetchRequest *allFeedbackData = [[NSFetchRequest alloc] init];
	[allFeedbackData setEntity:[NSEntityDescription entityForName:@"FeedbackData" inManagedObjectContext:threadContext]];
	[allFeedbackData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *feedbackArray = [threadContext executeFetchRequest:allFeedbackData error:&error];
	[allFeedbackData release];
	for (NSManagedObject *feedback in feedbackArray)
	{
		[threadContext deleteObject:feedback];
	}
    
    NSFetchRequest *allFeedbackListData = [[NSFetchRequest alloc] init];
	[allFeedbackListData setEntity:[NSEntityDescription entityForName:@"AnswerData" inManagedObjectContext:threadContext]];
	[allFeedbackListData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *feedbackListArray = [threadContext executeFetchRequest:allFeedbackListData error:&error];
	[allFeedbackListData release];
	for (NSManagedObject *feedbackList in feedbackListArray)
	{
		[threadContext deleteObject:feedbackList];
	}
    
	NSFetchRequest *allMatchData = [[NSFetchRequest alloc] init];
	[allMatchData setEntity:[NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:threadContext]];
	[allMatchData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	NSArray *matchArray = [threadContext executeFetchRequest:allMatchData error:&error];
	[allMatchData release];
	for (NSManagedObject *match in matchArray)
	{
		[threadContext deleteObject:match];
	}
    
    [appDelegate saveContext:threadContext];
    [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
    
    [pool drain];
}

- (void)clearServerMatchData
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    [self clearMatchData];

    SEL theSelector = @selector(sendDebugRequest:withData:);
    NSMethodSignature *sig = [self methodSignatureForSelector:theSelector];
    NSInvocation *theInvocation = [NSInvocation invocationWithMethodSignature:sig];
    [theInvocation setTarget:self];
    [theInvocation setSelector:theSelector];
    
    NSString *firstArgument = @"clearMatchData";
    NSIndexPath *secondArgument = nil;
    [theInvocation setArgument:&firstArgument atIndex:2];
    [theInvocation setArgument:&secondArgument atIndex:3];
    [theInvocation retainArguments]; 
    [theInvocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    
    [pool drain];
}

- (void)clearAllServerData
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    SEL theSelector = @selector(sendDebugRequest:withData:);
    NSMethodSignature *sig = [self methodSignatureForSelector:theSelector];
    NSInvocation *theInvocation = [NSInvocation invocationWithMethodSignature:sig];
    [theInvocation setTarget:self];
    [theInvocation setSelector:theSelector];
    
    NSString *firstArgument = @"clearServerData";
    NSIndexPath *secondArgument = nil;
    [theInvocation setArgument:&firstArgument atIndex:2];
    [theInvocation setArgument:&secondArgument atIndex:3];
    [theInvocation retainArguments]; 
    [theInvocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    
    [pool drain];
}

- (void)sendDebugRequest:(NSString*)task withData:(NSDictionary*)requestData
{
	NSString *jsonRequestString = nil;
	if(requestData != nil)
	{
		SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
		jsonRequestString = [jsonWriter stringWithObject:requestData];
		[jsonWriter release];
	}

	[appDelegate didStartNetworking];

	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/mobile/debug.php", appDelegate.apiHost]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setAllowCompressedResponse:YES];
	[request setShouldWaitToInflateCompressedResponses:NO];
    [request setUsername:@"yongopal"];
    [request setPassword:yongoApiKey];
    [request setValidatesSecureCertificate:NO];

	// set post data
	[request setPostValue:development forKey:@"development"];
	if(task != nil) [request setPostValue:task forKey:@"task"];
	NSString *udid = [OpenUDID value];
	[request setPostValue:udid forKey:@"udid"];
	if(jsonRequestString != nil) [request setPostValue:jsonRequestString forKey:@"data"];
	[request startSynchronous];

    bool isError = NO;
	NSError *error = [request error];
	NSString *json_string = nil;
	NSMutableDictionary *apiResult = nil;

	if (!error)
	{
		// set status code
		int statusCode = [request responseStatusCode];
		if(statusCode == 200)
		{
			json_string = [request responseString];
			
			// process request data
			SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
			id jsonObject = [jsonParser objectWithString:json_string error:nil];
			[jsonParser release];
			
			// check if data is valid json data
			if(jsonObject != nil)
			{
				apiResult = jsonObject;
				
				// check for api errors
				NSDictionary *serverError = [apiResult objectForKey:@"error"];
				if([serverError count] != 0)
				{
					NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Request Error", @"title", [serverError valueForKey:@"description"], @"message", nil];
					[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
					[alertContent release];
				}
                else
                {
                    isError = YES;
                }
				
				// check version
				double apiVersion = [[apiResult valueForKey:@"version"] doubleValue];
                double appVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] doubleValue];
                if(apiVersion > appVersion)
				{
					[appDelegate.mainNavController performSelectorOnMainThread:@selector(popToRootViewControllerAnimated:) withObject:nil waitUntilDone:NO];
					
					NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"API Error", @"title", @"This version is no longer supported.\nPlease download the latest version.", @"message", nil];
					[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
					[alertContent release];
					
					[apiResult setValue:nil forKey:@"result"];
				}
				
				[self performSelectorOnMainThread:@selector(processResults:) withObject:apiResult	waitUntilDone:YES];
			}
			else
			{
                isError = YES;
				NSLog(@"raw result: %@", json_string);
			}
		}
		else
		{
            isError = YES;
			NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Network Error", @"title", [NSString stringWithFormat:@"status code: %d", statusCode], @"message", nil];
			[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
			[alertContent release];
		}
	}
	else
	{
        isError = YES;
		NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Network Error", @"title", [NSString stringWithFormat:@"%@", error], @"message", nil];
		[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
		[alertContent release];
	}
    
    // log results
    NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
    [logData setValue:appDelegate.apiHost forKey:@"server"];
    [logData setValue:@"debug" forKey:@"requestType"];
    [logData setValue:task forKey:@"task"];
    [logData setValue:jsonRequestString forKey:@"requestData"];
    [logData setValue:json_string forKey:@"resultData"];
    [logData setValue:[NSNumber numberWithBool:isError] forKey:@"isError"];
    [appDelegate.apiRequest performSelectorOnMainThread:@selector(logApiResults:) withObject:logData waitUntilDone:NO];
    [logData release];

	[appDelegate didStopNetworking];
    [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
}

- (void)processResults:(NSDictionary*)results
{
	if([[results valueForKey:@"task"] isEqualToString:@"clearServerData"])
	{
        [appDelegate.prefs removeObjectForKey:@"deviceNo"];
		[appDelegate.prefs removeObjectForKey:@"memberNo"];
		[appDelegate.prefs synchronize];
		exit(0);
	}
}

- (void)setProgressWithObject:(NSNumber*)progress
{
    [self.progressView setProgress:[progress floatValue]];
}

- (void)processImportedChatData:(NSDictionary*)jsonObject
{
    [self.loadingLabel performSelectorOnMainThread:@selector(setText:) withObject:@"Saving Data" waitUntilDone:NO];

    [self performSelectorOnMainThread:@selector(setProgressWithObject:) withObject:[NSNumber numberWithFloat:0.0] waitUntilDone:NO];

    NSArray *messages = [[jsonObject valueForKey:@"result"] valueForKey:@"chatData"];

    NSMutableArray *photos = [[NSMutableArray alloc] init];
    
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *chatEntity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:threadContext];
    [request setEntity:chatEntity];
    [request setIncludesPropertyValues:NO];
    
    float totalMessages = [messages count];
    
    int matchNo = 0;
    float index = 1;
    NSError *error = nil;
    for(NSDictionary *chatData in messages)
    {
        NSAutoreleasePool *loopPool = [NSAutoreleasePool new];
        
        matchNo = [[chatData valueForKey:@"matchNo"] intValue];

        NSFetchRequest *matchDataFetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:threadContext];
        [matchDataFetchRequest setEntity:entity];
        [matchDataFetchRequest setIncludesPropertyValues:NO];

        NSPredicate *matchNoPredicate = [NSPredicate predicateWithFormat:@"matchNo = %d", matchNo];
        [matchDataFetchRequest setPredicate:matchNoPredicate];

        NSArray *matchDataSet = [threadContext executeFetchRequest:matchDataFetchRequest error:&error];
        [matchDataFetchRequest release];
        
        // don't import messages if match doesn't exist
        if([matchDataSet count] == 0)
        {
            [loopPool drain];
            continue;
        }

        MatchData *matchData = [matchDataSet objectAtIndex:0];

        [self performSelectorOnMainThread:@selector(setProgressWithObject:) withObject:[NSNumber numberWithFloat:(index / totalMessages)] waitUntilDone:NO];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo = %d AND messageNo = %d", matchNo, [[chatData valueForKey:@"messageNo"] intValue]]];
        [request setPredicate:predicate];
        
        NSUInteger count = [threadContext countForFetchRequest:request error:&error];
        
        if(count == 0)
        {
            // save in core data
            NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"ChatData" inManagedObjectContext:threadContext];
            
            // set matchNo
            [newManagedObject setValue:[NSNumber numberWithInt:matchNo] forKey:@"matchNo"];
            
            // set messageNo
            [newManagedObject setValue:[NSNumber numberWithInt:[[chatData valueForKey:@"messageNo"] intValue]] forKey:@"messageNo"];
            
            // set key
            [newManagedObject setValue:[chatData valueForKey:@"key"] forKey:@"key"];
            
            // set sender
            NSInteger sender = [[chatData valueForKey:@"sender"] intValue];
            [newManagedObject setValue:[NSNumber numberWithInt:sender] forKey:@"sender"];
            
            // set receiver
            NSInteger receiver = [[chatData valueForKey:@"receiver"] intValue];
            [newManagedObject setValue:[NSNumber numberWithInt:receiver] forKey:@"receiver"];
            
            // set is image
            if([[chatData valueForKey:@"isImage"] intValue] == 1)
            {
                [photos addObject:chatData];
                [downloadPool addObject:[chatData valueForKey:@"key"]];

                [newManagedObject setValue:[NSNumber numberWithBool:YES] forKey:@"isImage"];
                
                NSManagedObject *newManagedObject2 = [NSEntityDescription insertNewObjectForEntityForName:@"ImageData" inManagedObjectContext:threadContext];
                [newManagedObject2 setValue:[NSNumber numberWithInt:[[chatData valueForKey:@"messageNo"] intValue]] forKey:@"messageNo"];
                [newManagedObject2 setValue:[chatData valueForKey:@"key"] forKey:@"key"];
                
                if([chatData valueForKey:@"fileNo"] != nil && [chatData valueForKey:@"fileNo"] != [NSNull null])
                {
                    if([chatData valueForKey:@"missionNo"] != [NSNull null] && [chatData valueForKey:@"missionNo"] != nil)
                    {
                        NSNumber *missionNo = [NSNumber numberWithInt:[[chatData valueForKey:@"missionNo"] intValue]];
                        [newManagedObject2 setValue:missionNo forKey:@"missionNo"];
                        [newManagedObject2 setValue:[chatData valueForKey:@"description"] forKey:@"mission"];
                    }

                    [newManagedObject2 setValue:[chatData valueForKey:@"caption"] forKey:@"caption"];
                    [newManagedObject2 setValue:[NSNumber numberWithFloat:[[chatData valueForKey:@"latitude"] floatValue]] forKey:@"latitude"];
                    [newManagedObject2 setValue:[NSNumber numberWithFloat:[[chatData valueForKey:@"longitude"] floatValue]] forKey:@"longitude"];
                    [newManagedObject2 setValue:[chatData valueForKey:@"cityName"] forKey:@"cityName"];
                    [newManagedObject2 setValue:[chatData valueForKey:@"provinceName"] forKey:@"provinceName"];
                    [newManagedObject2 setValue:[chatData valueForKey:@"provinceCode"] forKey:@"provinceCode"];
                    [newManagedObject2 setValue:[chatData valueForKey:@"countryName"] forKey:@"countryName"];
                    [newManagedObject2 setValue:[chatData valueForKey:@"countryCode"] forKey:@"countryCode"];
                    [newManagedObject2 setValue:[chatData valueForKey:@"locationName"] forKey:@"locationName"];
                    [newManagedObject2 setValue:[chatData valueForKey:@"locationId"] forKey:@"locationId"];
                    
                    NSString *captionText = [chatData valueForKey:@"caption"];
                    CGSize captionSize = {180.0f, 99999.0f};		// width and height of text area
                    CGSize size = [captionText sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:captionSize lineBreakMode:UILineBreakModeWordWrap];
                    
                    [newManagedObject2 setValue:[NSNumber numberWithFloat:size.height] forKey:@"captionHeight"];
                }
                
                // set status
                if([[chatData valueForKey:@"sender"] intValue] != [appDelegate.prefs integerForKey:@"memberNo"])
                {
                    [newManagedObject setValue:[NSNumber numberWithInt:1] forKey:@"status"];
                }
                else
                {
                    [newManagedObject setValue:[NSNumber numberWithInt:2] forKey:@"status"];
                }
                
                // set chat data relationship
                [newManagedObject2 setValue:newManagedObject forKey:@"chatData"];
            }
            else
            {
                // set message
                if([chatData valueForKey:@"message"] != [NSNull null] && [chatData valueForKey:@"message"] != nil)
                {
                    [newManagedObject setValue:[chatData valueForKey:@"message"] forKey:@"message"];
                    
                    // set with and height for text
                    NSString *messageText = [chatData valueForKey:@"message"];
                    CGSize textSize = {180.0f, 99999.0f};		// width and height of text area
                    CGSize size = [messageText sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
                    [newManagedObject setValue:[NSNumber numberWithFloat:size.width] forKey:@"textWidth"];
                    [newManagedObject setValue:[NSNumber numberWithFloat:size.height] forKey:@"textHeight"];
                }
                
                // set status
                [newManagedObject setValue:[NSNumber numberWithInt:0] forKey:@"status"];
            }
            
            // set date
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *sendDate = [formatter dateFromString:[chatData valueForKey:@"sendDate"]];
            [newManagedObject setValue:sendDate forKey:@"datetime"];
            [formatter release];
            
            // set detected language
            if([chatData valueForKey:@"detectedLanguage"] != [NSNull null] && [chatData valueForKey:@"detectedLanguage"] != nil)
            {
                [newManagedObject setValue:[chatData valueForKey:@"detectedLanguage"] forKey:@"detectedLanguage"];
            }
            
            // set match data relationship
            [newManagedObject setValue:matchData forKey:@"matchData"];
            
            // save
            UIApplication *yongopalApp = [UIApplication sharedApplication];
            [appDelegate performSelectorOnMainThread:@selector(setApplicationBadgeNumber:) withObject:[NSNumber numberWithInt:yongopalApp.applicationIconBadgeNumber-1] waitUntilDone:NO];
            
            int newMessageAlert = [appDelegate.prefs integerForKey:@"newMessageAlert"];
            [appDelegate.prefs setInteger:newMessageAlert - 1 forKey:@"newMessageAlert"];
            [appDelegate.prefs synchronize];
        }
        index = index + 1;
        [loopPool drain];
    }
    [appDelegate saveContext:threadContext];
    [request release];

    if([photos count] > 0)
    {
        [self.loadingLabel performSelectorOnMainThread:@selector(setText:) withObject:@"Restoring Photos" waitUntilDone:NO];

        [self.progressView2 performSelectorOnMainThread:@selector(setHidden:) withObject:NO waitUntilDone:NO];
        totalPhotos = [photos count];
        downloadProgress = 0;
        for(NSDictionary *photoData in photos)
        {
            [self downloadThumbnail:[photoData valueForKey:@"messageNo"]];
        }
    }
    else
    {
        [self performSelectorOnMainThread:@selector(setProgressWithObject:) withObject:[NSNumber numberWithFloat:1.0] waitUntilDone:NO];
        [self.loadingView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
        [self.spinner performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
    [photos release];
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
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Configure the cell...
	NSDictionary *dictionary = [self.listOfItems objectAtIndex:indexPath.section];
	NSArray *array = [dictionary objectForKey:@"settings"];
	NSString *cellValue = [array objectAtIndex:indexPath.row];
	cell.textLabel.text = cellValue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
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

	if(indexPath.section == 0)
	{
        if(indexPath.row == 0)
        {
            DebugSettingsViewController *debugSettingsController = [[DebugSettingsViewController alloc] initWithNibName:@"DebugSettingsViewController" bundle:nil];
            [self.navigationController pushViewController:debugSettingsController animated:YES];
            [debugSettingsController release];
        }
        if(indexPath.row == 1)
		{
			LogListController *logController = [[LogListController alloc] initWithNibName:@"LogListController" bundle:nil];
			[self.navigationController pushViewController:logController animated:YES];
			[logController release];
		}
        else if(indexPath.row == 2)
        {
            if([[UIDevice currentDevice].systemVersion floatValue] >= 5.0)
            {
                UIAlertView *prompt = [[UIAlertView alloc]
                                       initWithTitle:@"Enter Access Code"
                                       message:@"Please enter the access code to unlock features"
                                       delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                                       otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
                [prompt setAlertViewStyle:UIAlertViewStyleSecureTextInput];
                [prompt setTag:100];
                [prompt show];
                [prompt release];
            }
            else
            {
                UIAlertView *prompt = [[UIAlertView alloc]
                                       initWithTitle:@"Enter Access Code"
                                       message:@"Please enter the access code to unlock features\n\n\n"
                                       delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                                       otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
                UITextField *emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 98.0, 260.0, 31.0)];
                [emailTextField setBackgroundColor:[UIColor whiteColor]];
                [emailTextField setBorderStyle:UITextBorderStyleBezel];
                [emailTextField setSecureTextEntry:YES];
                [emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
                [emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [emailTextField setTag:999];
                [emailTextField becomeFirstResponder];
                [prompt addSubview:emailTextField];
                [prompt setTag:100];
                [prompt show];
                [prompt release];
                [emailTextField release];
            }
        }
        else if(indexPath.row == 3)
		{
			[appDelegate.prefs setObject:[NSNumber numberWithBool:YES] forKey:@"soundEnabled"];
			[appDelegate.prefs setObject:[NSNumber numberWithBool:YES] forKey:@"alertEnabled"];
			[appDelegate.prefs setObject:[NSNumber numberWithBool:YES] forKey:@"badgeEnabled"];
			[appDelegate.prefs synchronize];
			[appDelegate registerDevice];
            
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:@"Done" 
								  message:@"This device has been re-registered for push notifications."
								  delegate:self
								  cancelButtonTitle:nil
								  otherButtonTitles:@"OK", nil];
			[alert setDelegate:self];
			[alert show];
			[alert release];
		}
        else if(indexPath.row == 4)
        {
            if([appDelegate.networkStatus boolValue] == YES && [appDelegate.wifiStatus boolValue] == YES)
            {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Are you sure?" 
                                      message:@"This might take a while."
                                      delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
                                      otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
                [alert setDelegate:self];
                [alert setTag:10];
                [alert show];
                [alert release];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Oops" 
                                      message:@"You must be connected to a WiFi network."
                                      delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
                [alert setDelegate:self];
                [alert show];
                [alert release];
            }
        }
		else if(indexPath.row == 5)
		{
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:@"Warning!" 
								  message:@"This will clear all chat data on this device."
								  delegate:self
								  cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
								  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
			[alert setDelegate:self];
			[alert setTag:0];
			[alert show];
			[alert release];
		}
		else if(indexPath.row == 6)
		{
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:@"Warning!" 
								  message:@"This will clear all guide data on this device."
								  delegate:self
								  cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
								  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
			[alert setDelegate:self];
			[alert setTag:1];
			[alert show];
			[alert release];
		}
        else if(indexPath.row == 7)
        {
            SelectServerController *serverController = [[SelectServerController alloc] initWithNibName:@"SelectServerController" bundle:nil];
            [self.navigationController pushViewController:serverController animated:YES];
            [serverController release];
        }
		else if(indexPath.row == 8)
		{
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:@"Warning!" 
								  message:@"This will wipe all current matches."
								  delegate:self
								  cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
								  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
			[alert setDelegate:self];
			[alert setTag:2];
			[alert show];
			[alert release];
		}
		else if(indexPath.row == 9)
		{
			UIAlertView *alert = [[UIAlertView alloc]
								  initWithTitle:@"Warning!" 
								  message:@"This will wipe all data on the server and the app will terminate."
								  delegate:self
								  cancelButtonTitle:NSLocalizedString(@"cancelButton", nil)
								  otherButtonTitles:NSLocalizedString(@"okButton", nil), nil];
			[alert setDelegate:self];
			[alert setTag:3];
			[alert show];
			[alert release];
		}
	}
}

- (ImageData*)getImageForKey:(NSString*)key withContext:(NSManagedObjectContext*)passedContext
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *imageEntity = [NSEntityDescription entityForName:@"ImageData" inManagedObjectContext:passedContext];
    [request setEntity:imageEntity];
    [request setReturnsObjectsAsFaults:NO];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key = %@", key];
	[request setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [passedContext executeFetchRequest:request error:&error];
	
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
	ImageData *imageObject = nil;
	if([fetchedObjects count] > 0)
	{
		imageObject = [fetchedObjects objectAtIndex:0];
	}
	[request release];
	
	return imageObject;
}

- (void)downloadThumbnail:(NSNumber*)messageNo
{
	NSMutableDictionary *downloadRequestData = [[NSMutableDictionary alloc] init];
	[downloadRequestData setValue:messageNo forKey:@"messageNo"];
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
    {
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 370] forKey:@"width"];
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 280] forKey:@"height"];
    }
    else
    {
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 185] forKey:@"width"];
        [downloadRequestData setValue:[NSString stringWithFormat:@"%d", 140] forKey:@"height"];
    }

	[self.apiRequest getAsyncDataFromServer:@"chat" withTask:@"downloadPhoto" withData:downloadRequestData progressDelegate:self.progressView2];
    
	[downloadRequestData release];
}

- (void)setThumbnailData:(NSDictionary*)thumbnailData
{
    UIImage *image = [thumbnailData valueForKey:@"imageData"];
    NSNumber *messageNo = [thumbnailData valueForKey:@"messageNo"];
    NSString *key = [thumbnailData valueForKey:@"key"];
    NSString *url = [thumbnailData valueForKey:@"url"];
    
    // create managed object context for this thread
    NSManagedObjectContext *threadContext = [ThreadMOC context];
    
    // get chat object
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *chatEntity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:threadContext];
    [request setEntity:chatEntity];
    [request setReturnsObjectsAsFaults:NO];
    
	NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"messageNo = %d", [messageNo intValue]]];
	[request setPredicate:predicate];
    
	NSError *error = nil;
	NSArray *fetchedObjects = [threadContext executeFetchRequest:request error:&error];
	[request release];
	
	if(fetchedObjects == nil)
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
	// set status and thumbnail image
    ChatData *chatObject = [fetchedObjects objectAtIndex:0];
	[chatObject setValue:[NSNumber numberWithInt:0] forKey:@"status"];
    NSString *thumbnailFile = [UtilityClasses saveImageData:UIImageJPEGRepresentation(image, 1.0) named:@"thumbnail" withKey:key overwrite:YES];
    [chatObject setValue:thumbnailFile forKey:@"thumbnailFile"];
    
    // set url for image
    ImageData *imageData = [self getImageForKey:key withContext:threadContext];
    [imageData setValue:url forKey:@"url"];
    [appDelegate saveContext:threadContext];
    
    float currentProgress = downloadProgress / totalPhotos;
    [self performSelectorOnMainThread:@selector(setProgressWithObject:) withObject:[NSNumber numberWithFloat:currentProgress] waitUntilDone:NO];
    downloadProgress = downloadProgress + 1;

    if(downloadProgress == totalPhotos)
    {
        [self performSelectorOnMainThread:@selector(setProgressWithObject:) withObject:[NSNumber numberWithFloat:1.0] waitUntilDone:NO];
        [self.loadingView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
        [self.spinner performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
}


#pragma mark - action sheet delegate
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet.tag == 100)
    {
        UITextField *accessCodeField;
        if([[UIDevice currentDevice].systemVersion floatValue] >= 5.0)
        {
            accessCodeField = [actionSheet textFieldAtIndex:0];
        }
        else
        {
            accessCodeField = (UITextField*)[actionSheet viewWithTag:999];
            [accessCodeField resignFirstResponder];
        }

        if(buttonIndex == 1)
        {
            [appDelegate showLoading];
            NSOperationQueue *operation = [[[NSOperationQueue alloc] init] autorelease];
            NSInvocationOperation *pushUnlockViewOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(checkAccessCode:) object:accessCodeField.text];
            [operation addOperation:pushUnlockViewOperation];
            [pushUnlockViewOperation release];
        }
    }
    else if(actionSheet.tag == 10)
    {
        if(buttonIndex == 1)
		{
            [self.loadingLabel setText:@"Downloading Data"];
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            [appDelegate.window addSubview:self.loadingView];
            [self.spinner startAnimating];
            [self.progressView setProgress:0.0];
            
            NSMutableDictionary *downloadRequestData = [[NSMutableDictionary alloc] init];
            [downloadRequestData setValue:[NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]] forKey:@"memberNo"];
            
            UpdateMatchListOperation *updateMatchOperation = [[UpdateMatchListOperation alloc] init];
            [receiveOperationQueue addOperation:updateMatchOperation];
            [updateMatchOperation release];

            [self.apiRequest sendAsyncServerRequest:@"chat" withTask:@"getAllMessages" withData:downloadRequestData progressDelegate:progressView];
            [downloadRequestData release];
        }
    }
	else if(actionSheet.tag == 0)
	{
		if(buttonIndex == 1)
		{
            [appDelegate showLoading];
            [NSFetchedResultsController deleteCacheWithName:nil];
			[self performSelectorInBackground:@selector(clearChatData) withObject:nil];
		}
	}
	else if(actionSheet.tag == 1)
	{
		if(buttonIndex == 1)
		{
            [appDelegate showLoading];
            [NSFetchedResultsController deleteCacheWithName:nil];
            [self performSelectorInBackground:@selector(clearMatchData) withObject:nil];
		}
	}
	else if(actionSheet.tag == 2)
	{
		if(buttonIndex == 1)
		{
            [appDelegate showLoading];
            [NSFetchedResultsController deleteCacheWithName:nil];
            [self performSelectorInBackground:@selector(clearServerMatchData) withObject:nil];
		}
	}
	else if(actionSheet.tag == 3)
	{
		if(buttonIndex == 1)
		{
            [appDelegate showLoading];
            [NSFetchedResultsController deleteCacheWithName:nil];
            [self performSelectorInBackground:@selector(clearAllServerData) withObject:nil];
		}
	}
}

#pragma mark - API request delegate
- (void)didReceiveJson:(NSDictionary*)jsonObject andHeaders:(NSDictionary*)headers
{
    if([[jsonObject valueForKey:@"task"] isEqualToString:@"getAllMessages"])
    {
        NSInvocationOperation *processOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processImportedChatData:) object:jsonObject];
        [receiveOperationQueue addOperation:processOperation];
        [processOperation release];
        //[self performSelectorInBackground:@selector(processImportedChatData:) withObject:jsonObject];
    }
}

- (void)didReceiveBinary:(NSData*)data andHeaders:(NSDictionary*)headers
{
    // if task was download photo get message number
    int messageNo = [[headers objectForKey:@"X-Yongopal-Messageno"] intValue];
    
    // and key
    NSString *key = [headers objectForKey:@"X-Yongopal-Key"];
    
    // and short url
    NSString *shortUrl = [headers objectForKey:@"X-Yongopal-Shorturl"];
    
    // hand over downloaded photo
    UIImage *downloadedImage = [UIImage imageWithData:data];
    NSDictionary *photoData = [[NSDictionary alloc] initWithObjectsAndKeys:
                               downloadedImage, @"imageData",
                               [NSNumber numberWithInt:messageNo], @"messageNo",
                               key, @"key",
                               shortUrl, @"url", nil];
    
    NSInvocationOperation *thumbOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(setThumbnailData:) object:photoData];
    [receiveOperationQueue addOperation:thumbOperation];
    [thumbOperation release];
    [photoData release];
}

@end
