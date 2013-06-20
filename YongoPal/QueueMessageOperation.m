//
//  QueueMessageOperation.m
//  Wander
//
//  Created by Jiho Kang on 1/12/12.
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

#import "QueueMessageOperation.h"
#import "UtilityClasses.h"

@implementation QueueMessageOperation
@synthesize matchData;
@synthesize message;
@synthesize key;
@synthesize insertedMessage;

- (id)initWithMatchData:(MatchData*)data andMessage:(NSString*)messageString resendWithObject:(NSManagedObject*)object
{
    self = [super init];
    
    if(self != nil)
    {
        if(data == nil || messageString == nil)
        {
            [self release];
            return nil;
        }

        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        context = [[ThreadMOC alloc] init];
        
        self.matchData = (MatchData*)[context objectWithID:[data objectID]];
        matchNo = [[matchData valueForKey:@"matchNo"] intValue];
        partnerNo = [[matchData valueForKey:@"partnerNo"] intValue];
        
        self.message = messageString;
        
        if(object != nil)
        {
            self.insertedMessage = (ChatData*)[context objectWithID:[object objectID]];
            self.key = [self.insertedMessage valueForKey:@"key"];
        }
    }
    
    return self;
}

- (void)dealloc
{
    self.matchData = nil;
    self.message = nil;
    self.key = nil;
    self.insertedMessage = nil;
    [context release];
    [super dealloc];
}

- (void)main
{
    @try
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        NSDictionary *requestData = nil;
        if([self isCancelled] == NO)
        {
            if(self.insertedMessage == nil)
            {
                requestData = [self sendMessage];
            }
            else
            {
                requestData = [self resendMessage];
            }
        }
        
        if([self isCancelled] == NO)
        {
            if(requestData != nil)
            {
                NSMutableDictionary *result = [NSMutableDictionary dictionary];
                [result setValue:requestData forKey:@"requestData"];
                [result setValue:[self.insertedMessage objectID] forKey:@"objectID"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldSendMessageToServer" object:nil userInfo:result];
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

#pragma mark - text devlivery methods
- (NSDictionary*)sendMessage
{
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    NSString *messageString = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // save in core data
    ChatData *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"ChatData" inManagedObjectContext:context];
    
    // get object id
    self.insertedMessage = newManagedObject;
    
    // set key for message
    NSString *currentKey = [UtilityClasses generateKey];
    [newManagedObject setKey:currentKey];
    
    // set message key in the message pool
    [dnc postNotificationName:@"shouldAddToTextPool" object:nil userInfo:[NSDictionary dictionaryWithObject:currentKey forKey:@"key"]];
    // scroll to last row
    [dnc postNotificationName:@"shouldScrollToBottomAnimated" object:nil];
    
    // set matchNo
    [newManagedObject setMatchNo:[NSNumber numberWithInt:matchNo]];
    
    // set sender
    [newManagedObject setSender:[NSNumber numberWithInt:[appDelegate.prefs integerForKey:@"memberNo"]]];
    
    // set receiver
    [newManagedObject setReceiver:[NSNumber numberWithInt:partnerNo]];
    
    // set message
    [newManagedObject setMessage:messageString];
    
    // set with and height for text
    CGSize textSize = {180.0f, 99999.0f};		// width and height of text area
    CGSize size = [messageString sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
    [newManagedObject setTextWidth:[NSNumber numberWithFloat:size.width]];
    [newManagedObject setTextHeight:[NSNumber numberWithFloat:size.height]];
    
    // set status
    [newManagedObject setStatus:[NSNumber numberWithInt:1]];
    
    // set match data relationship
    [newManagedObject setMatchData:self.matchData];

    // save
    [appDelegate saveContext:context];
    
    // prepare data
    int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setValue:currentKey forKey:@"key"];
    [requestData setValue:[NSString stringWithFormat:@"%d", matchNo] forKey:@"matchNo"];
    [requestData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
    [requestData setValue:[NSString stringWithFormat:@"%d", partnerNo] forKey:@"partnerNo"];
    [requestData setValue:[appDelegate.prefs valueForKey:@"firstName"] forKey:@"firstName"];
    [requestData setValue:messageString forKey:@"message"];
    
    // if push alerts are disabled, check for new messages every send
    bool alertEnabled = [[appDelegate.prefs objectForKey:@"alertEnabled"] boolValue];
    if(alertEnabled == NO)
    {
        [dnc postNotificationName:@"shouldCheckNewMessages" object:nil];
    }
    
    return [requestData autorelease];
}

- (NSDictionary*)resendMessage
{
	// prepare data
	int memberNo = [appDelegate.prefs integerForKey:@"memberNo"];
	NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
	[requestData setValue:self.key forKey:@"key"];
	[requestData setValue:[NSString stringWithFormat:@"%d", matchNo] forKey:@"matchNo"];
	[requestData setValue:[NSString stringWithFormat:@"%d", memberNo] forKey:@"memberNo"];
	[requestData setValue:[NSString stringWithFormat:@"%d", partnerNo] forKey:@"partnerNo"];
	[requestData setValue:[appDelegate.prefs valueForKey:@"firstName"] forKey:@"firstName"];
	[requestData setValue:message forKey:@"message"];
	[requestData setValue:@"Y" forKey:@"resend"];
    
    return [requestData autorelease];
}

@end
