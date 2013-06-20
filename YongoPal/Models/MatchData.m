//
//  MatchData.m
//  Wander
//
//  Created by Jiho Kang on 2/7/12.
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

#import "MatchData.h"
#import "ChatData.h"
#import "FeedbackData.h"
#import "MissionData.h"


@implementation MatchData

@dynamic latitude;
@dynamic lastName;
@dynamic countryName;
@dynamic firstName;
@dynamic expireDate;
@dynamic timezoneOffset;
@dynamic shouldShowIntro;
@dynamic profileImage;
@dynamic lastMessageDatetime;
@dynamic provinceCode;
@dynamic intro;
@dynamic profileImageNo;
@dynamic partnerNo;
@dynamic email;
@dynamic update;
@dynamic regDatetime;
@dynamic birthday;
@dynamic recentMessage;
@dynamic muted;
@dynamic longitude;
@dynamic matchNo;
@dynamic status;
@dynamic countryCode;
@dynamic isQuickMatch;
@dynamic cityName;
@dynamic order;
@dynamic gender;
@dynamic open;
@dynamic timezone;
@dynamic activeDate;
@dynamic matchDatetime;
@dynamic chatData;
@dynamic missionData;
@dynamic feedbackData;

- (NSError*)errorFromOriginalError:(NSError*)originalError error:(NSError*)additionalError
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    NSMutableArray *errors = [NSMutableArray arrayWithObject:additionalError];
    
    if([originalError code] == NSValidationMultipleErrorsError)
    {
        [userInfo addEntriesFromDictionary:[originalError userInfo]];
        [errors addObjectsFromArray:[userInfo objectForKey:NSDetailedErrorsKey]];
    }
    else
    {
        [errors addObject:originalError];
    }
    
    [userInfo setObject:errors forKey:NSDetailedErrorsKey];
    
    return [NSError errorWithDomain:NSCocoaErrorDomain code:NSValidationMultipleErrorsError userInfo:userInfo];
}

- (BOOL)validateForInsert:(NSError **)error
{
    BOOL isValid = [super validateForInsert:error];
    
    if(self.matchNo != nil)
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
        [matchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"matchNo = %d", [self.matchNo intValue]];
        [matchRequest setPredicate:predicate];
        [matchRequest setIncludesPropertyValues:NO];
        
        NSError *_error = nil;
        int checkMatchNo = [context countForFetchRequest:matchRequest error:&_error];
        [matchRequest release];
        
        if(_error != nil)
        {
            NSLog(@"Unresolved error %@, %@", _error, [_error userInfo]);
            abort();
        }
        
        if(checkMatchNo > 1)
        {
            NSDictionary *err = [NSDictionary dictionaryWithObject:@"duplicate attribute matchNo for object MatchData" forKey:NSLocalizedDescriptionKey];
            
            _error = [[[NSError alloc] initWithDomain:@"com.yongopal.coredata" code:1022 userInfo:err] autorelease];
            
            if(*error == nil)
            {
                *error = _error;
            }
            else
            {
                *error = [self errorFromOriginalError:*error error:_error];
            }
            isValid = NO;
        }
    }

    return isValid;
}

@end
