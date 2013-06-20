//
//  SendMessageOperation.m
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

#import "SendMessageOperation.h"
#import "UtilityClasses.h"

@implementation SendMessageOperation
@synthesize insertedMessageID;
@synthesize requestData;

- (id)initWithRequestData:(NSDictionary*)data andObjectID:(NSManagedObjectID*)objectID
{
    self = [super init];
    
    if(self != nil)
    {
        if(data == nil || objectID == nil)
        {
            [self release];
            return nil;
        }

        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        apiRequest = [[APIRequest alloc] init];
        [apiRequest setThreadPriority:1.0];

        self.requestData = data;
        self.insertedMessageID = objectID;
    }

    return self;
}

- (void)dealloc
{
    [apiRequest release];
    self.requestData = nil;
    self.insertedMessageID = nil;
    [super dealloc];
}

- (void)main
{
    @try
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        if([self isCancelled] == NO)
        {
            NSDictionary *apiResult = nil;
            if(self.requestData != nil)
            {
                apiResult = [self sendMessageToServer:self.requestData];
            }

            if(apiResult != nil)
            {
                NSMutableDictionary *result = [NSMutableDictionary dictionary];
                [result setValue:apiResult forKey:@"apiResult"];
                [result setValue:self.insertedMessageID forKey:@"objectID"];

                [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldConfirmSentMessage" object:nil userInfo:result];
                
                if([[apiResult valueForKey:@"messageNo"] intValue] != 0)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldUpdatePartnerData" object:nil userInfo:result];
                }
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
- (NSDictionary*)sendMessageToServer:(NSDictionary*)messageData
{
    NSDictionary *apiResult = [apiRequest sendServerRequest:@"chat" withTask:@"sendMessage" withData:messageData];
    return apiResult;
}

@end
