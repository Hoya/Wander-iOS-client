//
//  Keys.m
//  Wander
//
//  Created by Jiho Kang on 11/9/11.
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

#import "Keys.h"


@implementation Keys

@dynamic key;
@dynamic keyString;
@dynamic instanceNo;

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

    if(self.keyString != nil)
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Keys" inManagedObjectContext:context];
        [request setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"keyString = %@",  self.keyString];
        [request setPredicate:predicate];
        [request setIncludesPropertyValues:NO];
        
        NSError *_error = nil;
        int checkKey = [context countForFetchRequest:request error:&_error];
        [request release];
        
        if(_error != nil)
        {
            NSLog(@"Unresolved error %@, %@", _error, [_error userInfo]);
            abort();
        }
        
        if(checkKey > 1)
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
