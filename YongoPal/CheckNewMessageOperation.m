//
//  CheckNewMessageOperation.m
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

#import "CheckNewMessageOperation.h"

@implementation CheckNewMessageOperation
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
    [context release];
    self.matchData = nil;
    [apiRequest release];
    [super dealloc];
}

- (void)main
{
    @try
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];

        if([self isCancelled] == NO)
        {
            NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
            NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
            [requestData setValue:memberNoString forKey:@"memberNo"];
            [requestData setValue:[NSString stringWithFormat:@"%d", matchNo] forKey:@"matchNo"];
            NSDictionary *results = [apiRequest sendServerRequest:@"chat" withTask:@"checkNewMessages" withData:requestData];
            [requestData release];
            
            if(results)
            {
                if([[results valueForKey:@"newMessages"] intValue] > 0)
                {
                    [dnc postNotificationName:@"shouldGetNewMessages" object:nil];
                }
                [dnc postNotificationName:@"shouldUpdatePartnerData" object:nil userInfo:[NSDictionary dictionaryWithObject:results forKey:@"apiResult"]];
                
                // update badge count
                int badgeCount = [[results valueForKey:@"badgeCount"] intValue];
                int newMatchAlert = [[results valueForKey:@"newMatchAlert"] intValue];
                int matchSuccessfulAlert = [[results valueForKey:@"matchSuccessfulAlert"] intValue];
                int newMessageAlert = [[results valueForKey:@"newMessageAlert"] intValue];
                int newMissionAlert = [[results valueForKey:@"newMissionAlert"] intValue];
                
                [appDelegate performSelectorOnMainThread:@selector(setApplicationBadgeNumber:) withObject:[NSNumber numberWithInt:badgeCount] waitUntilDone:NO];
                [appDelegate.prefs setInteger:newMatchAlert forKey:@"newMatchAlert"];
                [appDelegate.prefs setInteger:matchSuccessfulAlert forKey:@"matchSuccessfulAlert"];
                [appDelegate.prefs setInteger:newMessageAlert forKey:@"newMessageAlert"];
                [appDelegate.prefs setInteger:newMissionAlert forKey:@"newMissionAlert"];
                [appDelegate.prefs synchronize];
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

@end
