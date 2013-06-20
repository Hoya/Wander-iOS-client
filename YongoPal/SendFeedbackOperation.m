//
//  SendFeedbackOperation.m
//  Wander
//
//  Created by Jiho Kang on 10/8/11.
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

#import "SendFeedbackOperation.h"

@implementation SendFeedbackOperation
@synthesize matchData;
@synthesize insertedFeedbackData;
@synthesize checkedAnswerData;
@synthesize otherFeedback;

- (id)initWithMatchData:(MatchData*)currentMatchData andAnswer:(AnswerData*)answer andOtherFeedback:(NSString*)feedbackText
{
    self = [super init];
    
    if(self != nil)
    {        
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        context = [[ThreadMOC alloc] init];

        apiRequest = [[APIRequest alloc] init];
        [apiRequest setThreadPriority:0.0];
        
        if(currentMatchData == nil || answer == nil)
        {
            return nil;
        }

        self.matchData = (MatchData*)[context objectWithID:[currentMatchData objectID]];
        self.checkedAnswerData = (AnswerData*)[context objectWithID:[answer objectID]];
        if(feedbackText != nil && [feedbackText isEqualToString:@""])
        {
            self.otherFeedback = feedbackText;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [context release];
    [apiRequest release];
    self.matchData = nil;
    self.insertedFeedbackData = nil;
    self.checkedAnswerData = nil;
    self.otherFeedback = nil;
    [super dealloc];
}

- (void)main
{
    @try
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        if([self isCancelled] == NO)
        {
            int declinedMatchNo = [[self.matchData valueForKey:@"matchNo"] intValue];
            int checkedAnswer = [[self.checkedAnswerData valueForKey:@"answerNo"] intValue];
            
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"FeedbackData" inManagedObjectContext:context];
            [request setEntity:entity];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = %d", declinedMatchNo];
            [request setPredicate:predicate];
            [request setIncludesPropertyValues:NO];
            
            NSError *error = nil;
            int existingFeedback = [context countForFetchRequest:request error:&error];

            if(existingFeedback == 0)
            {
                // save in core data
                self.insertedFeedbackData = [NSEntityDescription insertNewObjectForEntityForName:@"FeedbackData" inManagedObjectContext:context];
                [insertedFeedbackData setValue:[NSNumber numberWithInt:checkedAnswer] forKey:@"answerNo"];
                [insertedFeedbackData setValue:[NSNumber numberWithInt:declinedMatchNo] forKey:@"matchNo"];
                [insertedFeedbackData setValue:[NSNumber numberWithBool:NO] forKey:@"sendConfirmed"];
                if(self.otherFeedback != nil) [insertedFeedbackData setValue:self.otherFeedback forKey:@"otherAnswer"];
                [insertedFeedbackData setValue:self.matchData forKey:@"matchData"];
                [insertedFeedbackData setValue:self.checkedAnswerData forKey:@"answerData"];
            }
            else
            {
                [request setIncludesPropertyValues:YES];
                NSArray *fetchedData = [context executeFetchRequest:request error:&error];
                self.insertedFeedbackData = [fetchedData objectAtIndex:0];
            }
            [request release];
            
            NSMutableDictionary *feedbackData = [[NSMutableDictionary alloc] init];
            NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
            [feedbackData setValue:memberNoString forKey:@"memberNo"];
            [feedbackData setValue:[NSString stringWithFormat:@"%d", declinedMatchNo] forKey:@"matchNo"];
            [feedbackData setValue:[NSString stringWithFormat:@"%d", checkedAnswer] forKey:@"answerNo"];
            if(self.otherFeedback != nil) [feedbackData setValue:self.otherFeedback forKey:@"otherAnswer"];
            NSDictionary *apiResult = [apiRequest sendServerRequest:@"feedback" withTask:@"sendFeedback" withData:feedbackData];
            [feedbackData release];
            
            if(apiResult)
            {
                if([apiResult valueForKey:@"feedbackNo"] != [NSNull null] && [apiResult valueForKey:@"feedbackNo"] != nil)
                {
                    [insertedFeedbackData setValue:[NSNumber numberWithBool:YES] forKey:@"sendConfirmed"];
                }
            }
            [appDelegate saveContext:context];
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
