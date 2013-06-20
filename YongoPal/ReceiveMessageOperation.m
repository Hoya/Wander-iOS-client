//
//  ReceiveMessageOperation.m
//  Wander
//
//  Created by Jiho Kang on 9/12/11.
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


#import "ReceiveMessageOperation.h"
#import "ChatData.h"

@implementation ReceiveMessageOperation
@synthesize matchData;

- (id)initWithMatchData:(MatchData*)data
{
    self = [super init];
    
    if(self != nil)
    {
        if(data == nil)
        {
            [self release];
            return nil;
        }

        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        context = [[ThreadMOC alloc] init];

        self.matchData = (MatchData*)[context objectWithID:[data objectID]];
        matchNo = [[self.matchData valueForKey:@"matchNo"] intValue];

        apiRequest = [[APIRequest alloc] init];
        [apiRequest setThreadPriority:0.1];
    }
    
    return self;
}

- (void)dealloc
{
    self.matchData = nil;
    [context release];
    [apiRequest release];
    [super dealloc];
}

- (void)main
{
    @try
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        NSArray *savedMessages = nil;
        if([self isCancelled] == NO)
        {
            NSArray *receivedMessages = [self getNewMessagesFromServer];

            if(receivedMessages != nil)
            {
                savedMessages = [self saveReceivedMessages:receivedMessages];
            }

            if(savedMessages != nil)
            {
                [self confirmReceived:savedMessages];
            }
        }
        [pool drain];
    }
    @catch (NSException *e)
    {
        if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
        {
            NSLog(@"Exception %@", e);
        }
    }
}

#pragma mark - receive methods
// receive new messages from server
- (NSArray*)getNewMessagesFromServer
{
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
    [requestData setValue:memberNoString forKey:@"memberNo"];
    [requestData setValue:[matchData valueForKey:@"matchNo"] forKey:@"matchNo"];
    
    NSDictionary *apiResult = [apiRequest sendServerRequest:@"chat" withTask:@"getNewMessages" withData:requestData];
    [requestData release];
    
    NSArray *newMessages = nil;
    if(apiResult)
    {
        newMessages = [apiResult valueForKey:@"chatData"];
    }
    return newMessages;
}

// save new messages to core data
- (NSArray*)saveReceivedMessages:(NSArray*)messages
{
    NSMutableArray *confirmMessages = [[NSMutableArray alloc] init];
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];

	if([messages count] > 0)
	{
		NSError *error = nil;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *chatEntity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:context];
        [request setEntity:chatEntity];
        [request setIncludesPropertyValues:NO];

		for(NSDictionary *chatData in messages)
		{
            NSAutoreleasePool *pool = [NSAutoreleasePool new];

			NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo = %d AND messageNo = %d", matchNo, [[chatData valueForKey:@"messageNo"] intValue]]];
			[request setPredicate:predicate];

			NSUInteger count = [context countForFetchRequest:request error:&error];
			
			if(count == 0)
			{
                [dnc postNotificationName:@"shouldScrollToBottomAnimated" object:nil];

				// save in core data
				NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"ChatData" inManagedObjectContext:context];
				
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
					[newManagedObject setValue:[NSNumber numberWithBool:YES] forKey:@"isImage"];
					
					NSManagedObject *newManagedObject2 = [NSEntityDescription insertNewObjectForEntityForName:@"ImageData" inManagedObjectContext:context];
					[newManagedObject2 setValue:[NSNumber numberWithInt:[[chatData valueForKey:@"messageNo"] intValue]] forKey:@"messageNo"];
					[newManagedObject2 setValue:[chatData valueForKey:@"key"] forKey:@"key"];

                    if([chatData valueForKey:@"fileNo"] != nil && [chatData valueForKey:@"fileNo"] != [NSNull null])
                    {
                        if([chatData valueForKey:@"missionNo"] != nil && [chatData valueForKey:@"missionNo"] != [NSNull null])
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
                        CGSize captionBounds = {180.0f, 99999.0f};		// width and height of text area
                        CGSize captionSize = [captionText sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:captionBounds lineBreakMode:UILineBreakModeWordWrap];

                        [newManagedObject2 setValue:[NSNumber numberWithFloat:captionSize.height] forKey:@"captionHeight"];
                    }
                    
                    // set chat data relationship
                    [newManagedObject2 setValue:newManagedObject forKey:@"chatData"];

					// set status
					[newManagedObject setValue:[NSNumber numberWithInt:1] forKey:@"status"];
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
                [newManagedObject setValue:self.matchData forKey:@"matchData"];
                
				// save
                UIApplication *yongopalApp = [UIApplication sharedApplication];
                [appDelegate performSelectorOnMainThread:@selector(setApplicationBadgeNumber:) withObject:[NSNumber numberWithInt:yongopalApp.applicationIconBadgeNumber-1] waitUntilDone:NO];
                [appDelegate saveContext:context];
                
                int newMessageAlert = [appDelegate.prefs integerForKey:@"newMessageAlert"];
                [appDelegate.prefs setInteger:newMessageAlert - 1 forKey:@"newMessageAlert"];
                [appDelegate.prefs synchronize];
			}
			[confirmMessages addObject:[chatData valueForKey:@"messageNo"]];
            [pool drain];
		}
        [request release];
	}

    return [confirmMessages autorelease];
}

// confirm that messages have been received to server
- (void)confirmReceived:(NSArray*)receivedMessages
{
    int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
    [requestData setValue:receivedMessages forKey:@"receivedMessages"];
    [requestData setValue:[NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"deviceNo"]] forKey:@"deviceNo"];
    
    [apiRequest sendServerRequest:@"chat" withTask:@"confirmReceived" withData:requestData];
    [requestData release];
    
    int updateCount = [[matchData valueForKey:@"update"] intValue] - [receivedMessages count];
    if(updateCount >= 0)
    {
        NSDictionary *updateData = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:updateCount] forKey:@"update"] forKey:@"apiResult"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldUpdatePartnerData" object:nil userInfo:updateData];
    }
}

@end