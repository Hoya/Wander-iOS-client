//
//  CountNewMessageOperation.m
//  Wander
//
//  Created by Jiho Kang on 10/6/11.
//  Copyright (c) 2011 YongoPal, Inc. All rights reserved.
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

#import "CountNewMessageOperation.h"
#import "MatchData.h"

@implementation CountNewMessageOperation

- (id)initWithMatchNo:(NSNumber*)matchNo
{
    self = [super init];
    
    if(self != nil)
    {        
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        context = [[ThreadMOC alloc] init];
        
        apiRequest = [[APIRequest alloc] init];
        [apiRequest setThreadPriority:0.1];
        if(matchNo != nil)
        {
            updateMatchNo = [matchNo intValue];
        }
        else
        {
            updateMatchNo = 0;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [context release];
    [apiRequest release];
    [super dealloc];
}

- (void)main
{
    @try
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        if([self isCancelled] == NO)
        {
            NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
            NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
            [requestData setValue:[NSString stringWithFormat:@"%d", updateMatchNo] forKey:@"matchNo"];
            [requestData setValue:memberNoString forKey:@"memberNo"];
            NSDictionary *apiResult = [apiRequest sendServerRequest:@"match" withTask:@"countNewMessages" withData:requestData];
            [requestData release];
            
            if(apiResult != nil)
            {
                if([apiResult valueForKey:@"activeMatches"] != [NSNull null])
                {
                    NSArray *activeMatches = [apiResult valueForKey:@"activeMatches"];
                    
                    NSError *error = nil;
                    NSFetchRequest *matchRequest = [[[NSFetchRequest alloc] init] autorelease];
                    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
                    [matchRequest setEntity:entity];
                    
                    for(NSDictionary *activeMatch in activeMatches)
                    {
                        int currentMatchNo = [[activeMatch valueForKey:@"matchNo"] intValue];
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo = %d", currentMatchNo]];
                        [matchRequest setPredicate:predicate];
                        
                        NSArray *fetchedObjects = [context executeFetchRequest:matchRequest error:&error];
                        if(fetchedObjects == nil)
                        {
                            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                            abort();
                        }

                        if([fetchedObjects count] == 0)
                        {
                            continue;
                        }

                        MatchData *selectedMatch = [fetchedObjects objectAtIndex:0];
                        
                        int newMessageCount = [[activeMatch valueForKey:@"newMessages"] intValue];
                        
                        if([[selectedMatch valueForKey:@"update"] intValue] != newMessageCount)
                        {
                            [selectedMatch setValue:[NSNumber numberWithInt:newMessageCount] forKey:@"update"];
                            
                            if([activeMatch valueForKey:@"recentMessage"] != [NSNull null])
                            {
                                NSString *recentMessage = [activeMatch valueForKey:@"recentMessage"];
                                if(recentMessage != nil && ![recentMessage isEqualToString:[selectedMatch valueForKey:@"recentMessage"]])
                                {
                                    [selectedMatch setValue:recentMessage forKey:@"recentMessage"];
                                }
                            }
                        }   
                    }
                    
                    [appDelegate.prefs synchronize];
                    [appDelegate saveContext:context];
                }
                
                if([apiResult valueForKey:@"badgeCount"] != [NSNull null])
                {
                    int badgeCount = [[apiResult valueForKey:@"badgeCount"] intValue];
                    [appDelegate performSelectorOnMainThread:@selector(setApplicationBadgeNumber:) withObject:[NSNumber numberWithInt:badgeCount] waitUntilDone:NO];
                }
                
                if([apiResult valueForKey:@"newMatchAlert"] != [NSNull null])
                {
                    int newMatchAlert = [[apiResult valueForKey:@"newMatchAlert"] intValue];
                    [appDelegate.prefs setInteger:newMatchAlert forKey:@"newMatchAlert"];
                }
                
                if([apiResult valueForKey:@"matchSuccessfulAlert"] != [NSNull null])
                {
                    int matchSuccessfulAlert = [[apiResult valueForKey:@"matchSuccessfulAlert"] intValue];
                    [appDelegate.prefs setInteger:matchSuccessfulAlert forKey:@"matchSuccessfulAlert"];
                }
                
                if([apiResult valueForKey:@"newMessageAlert"] != [NSNull null])
                {
                    int newMessageAlert = [[apiResult valueForKey:@"newMessageAlert"] intValue];
                    [appDelegate.prefs setInteger:newMessageAlert forKey:@"newMessageAlert"];
                }
                
                if([apiResult valueForKey:@"newMissionAlert"] != [NSNull null])
                {
                    int newMissionAlert = [[apiResult valueForKey:@"newMissionAlert"] intValue];
                    [appDelegate.prefs setInteger:newMissionAlert forKey:@"newMissionAlert"];
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

- (NSArray*)getActiveMatches
{
    NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
    [matchRequest setEntity:entity];
    [matchRequest setIncludesPropertyValues:NO];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"open = YES"];
    [matchRequest setPredicate:predicate];
    
    NSError *error = nil;
    int checkMatches = [context countForFetchRequest:matchRequest error:&error];
    
    NSArray *activeMatches = nil;
    if(checkMatches != 0)
    {
        [matchRequest setIncludesPropertyValues:YES];
        [matchRequest setReturnsObjectsAsFaults:NO];
        
        activeMatches = [context executeFetchRequest:matchRequest error:&error];
        
        if(activeMatches == nil)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    [matchRequest release];
    
    return activeMatches;
}

@end
