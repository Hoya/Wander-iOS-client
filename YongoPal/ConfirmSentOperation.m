//
//  ConfirmSentOperation.m
//  Wander
//
//  Created by Jiho Kang on 9/13/11.
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

#import "ConfirmSentOperation.h"
#import "ChatData.h"

@implementation ConfirmSentOperation
@synthesize insertedMessage;
@synthesize results;
@synthesize facebookSharePool;
@synthesize twitterSharePool;
@synthesize foursquareSharePool;

- (id)initWithResults:(NSDictionary*)confirmResults withObjectID:(NSManagedObjectID*)objectID
{
    self = [super init];
    
    if(self != nil)
    {
        if(confirmResults == nil || objectID == nil)
        {
            [self release];
            return nil;
        }

        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];

        context = [[ThreadMOC alloc] init];

        self.results = confirmResults;
        self.insertedMessage = (ChatData*)[context objectWithID:objectID];
        [context refreshObject:self.insertedMessage mergeChanges:YES];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.insertedMessage = nil;
    self.results = nil;
    self.facebookSharePool = nil;
    self.twitterSharePool = nil;
    self.foursquareSharePool = nil;
    [context release];
    [super dealloc];
}

- (void)main
{
    @try
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];

        if([self isCancelled] == NO && [results valueForKey:@"messageNo"] != [NSNull null])
        {
            NSNumber *messageNo = [NSNumber numberWithInt:[[results valueForKey:@"messageNo"] intValue]];
            
            NSString *currentKey = self.insertedMessage.key;
            NSDictionary *removeKeyInfo = [NSDictionary dictionaryWithObjectsAndKeys:currentKey, @"key", messageNo, @"messageNo", [results valueForKey:@"url"], @"url", nil];
            [dnc postNotificationName:@"shouldRemoveKey" object:nil userInfo:removeKeyInfo];
            
            [self.insertedMessage setMessageNo:messageNo];
            
            // set status to 0
            [self.insertedMessage setStatus:[NSNumber numberWithInt:0]];
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            
            NSDate* sourceDate = [dateFormat dateFromString:[self.results valueForKey:@"sendDate"]];

            [self.insertedMessage setDatetime:sourceDate];
            
            [dateFormat release];

            [appDelegate saveContext:context];
            
            // share on facebook
            if([self.facebookSharePool objectForKey:currentKey])
            {
                [dnc postNotificationName:@"shouldPostToFB" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:currentKey, @"key", nil]];
            }
            
            // share on twitter
            if([self.twitterSharePool objectForKey:currentKey])
            {
                [dnc postNotificationName:@"shouldTweet" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:currentKey, @"key", nil]];
            }
            
            // share on foursquare
            if([self.foursquareSharePool objectForKey:currentKey])
            {
                [dnc postNotificationName:@"shouldPostToFSQ" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:currentKey, @"key", nil]];
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
