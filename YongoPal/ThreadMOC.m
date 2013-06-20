//
//  ThreadMOC.m
//  Wander
//
//  Created by Jiho Kang on 2/3/12.
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

#import "ThreadMOC.h"
#import "YongoPalAppDelegate.h"

@implementation ThreadMOC

- (id)init
{
	self = [super init];
	if (self)
	{
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        [self setPersistentStoreCoordinator:[appDelegate persistentStoreCoordinator]];
        [self setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];

		// register core data notifications
        shouldCancelMerge = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeContextChanges:) name:NSManagedObjectContextDidSaveNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelMerge) name:@"willLogout" object:nil];
	}
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

+ (NSManagedObjectContext*)context
{
    return [[[ThreadMOC alloc] init] autorelease];
}

- (void)cancelMerge
{
    shouldCancelMerge = YES;
    [self reset];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)mergeContextChanges:(NSNotification *)notification
{
    if([NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:YES];
        return;
    }
    
    if(shouldCancelMerge == YES)
    {
        return;
    }

    [appDelegate.mainMOC lock];
    NSSet *updated = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    for(NSManagedObject *thing in updated)
    {
        [[appDelegate.mainMOC objectWithID:[thing objectID]] willAccessValueForKey:nil];
    }
    [appDelegate.mainMOC mergeChangesFromContextDidSaveNotification:notification];
    [appDelegate.mainMOC processPendingChanges];
    [appDelegate.mainMOC unlock];
}

@end
