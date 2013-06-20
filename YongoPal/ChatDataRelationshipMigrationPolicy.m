//
//  ChatDataRelationshipMigrationPolicy.m
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

#import "ChatDataRelationshipMigrationPolicy.h"
#import "MatchData.h"
#import "ImageData.h"

@implementation ChatDataRelationshipMigrationPolicy

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    // Create the managed object
    NSManagedObject *chatData = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName] inManagedObjectContext:[manager destinationContext]];

    [chatData setValue:[sInstance valueForKey:@"missionNo"] forKey:@"missionNo"];
    [chatData setValue:[sInstance valueForKey:@"datetime"] forKey:@"datetime"];
    [chatData setValue:[sInstance valueForKey:@"textHeight"] forKey:@"textHeight"];
    [chatData setValue:[sInstance valueForKey:@"message"] forKey:@"message"];
    [chatData setValue:[sInstance valueForKey:@"receiver"] forKey:@"receiver"];
    [chatData setValue:[sInstance valueForKey:@"thumbnailFile"] forKey:@"thumbnailFile"];
    [chatData setValue:[sInstance valueForKey:@"isImage"] forKey:@"isImage"];
    [chatData setValue:[sInstance valueForKey:@"key"] forKey:@"key"];
    [chatData setValue:[sInstance valueForKey:@"messageNo"] forKey:@"messageNo"];
    [chatData setValue:[sInstance valueForKey:@"matchNo"] forKey:@"matchNo"];
    [chatData setValue:[sInstance valueForKey:@"textWidth"] forKey:@"textWidth"];
    [chatData setValue:[sInstance valueForKey:@"sender"] forKey:@"sender"];
    [chatData setValue:[sInstance valueForKey:@"status"] forKey:@"status"];
    [chatData setValue:nil forKey:@"detectedLanguage"];

    // set match relationship
    NSError *fetchError;
    NSManagedObjectContext *context = [manager destinationContext];
    NSFetchRequest *matchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *matchEntity = [NSEntityDescription entityForName:@"MatchData" inManagedObjectContext:context];
    [matchRequest setEntity:matchEntity];
    [matchRequest setReturnsObjectsAsFaults:NO];
    
    NSPredicate *matchNoPredicate = [NSPredicate predicateWithFormat:@"matchNo = %d", [[sInstance valueForKey:@"matchNo"] intValue]];
    [matchRequest setPredicate:matchNoPredicate];
    
    
    NSArray *fetchedMatchDataObjects = [context executeFetchRequest:matchRequest error:&fetchError];
    if(fetchedMatchDataObjects == nil)
    {
        NSLog(@"Unresolved error %@", [fetchError localizedDescription]);
        abort();
    }
    
    if([fetchedMatchDataObjects count] > 0)
    {
        MatchData *matchDataObject = [fetchedMatchDataObjects objectAtIndex:0];
        [chatData setValue:matchDataObject forKey:@"matchData"];
    }
    [matchRequest release];

    // set image relationship
    NSFetchRequest *imageDataRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *imageDataEntity = [NSEntityDescription entityForName:@"ImageData" inManagedObjectContext:context];
    [imageDataRequest setEntity:imageDataEntity];
    [imageDataRequest setReturnsObjectsAsFaults:NO];

    NSPredicate *keyPredicate = [NSPredicate predicateWithFormat:@"key = %@", [sInstance valueForKey:@"key"]];
    [imageDataRequest setPredicate:keyPredicate];

    NSArray *fetchedImageDataObjects = [context executeFetchRequest:imageDataRequest error:&fetchError];
    if(fetchedImageDataObjects == nil)
    {
        NSLog(@"Unresolved error %@", [fetchError localizedDescription]);
        abort();
    }

    if([fetchedImageDataObjects count] > 0)
    {
        ImageData *imageDataObject = [fetchedImageDataObjects objectAtIndex:0];
        [chatData setValue:imageDataObject forKey:@"imageData"];
    }
    [imageDataRequest release];

    // Set up the association for the migration manager
    [manager associateSourceInstance:sInstance withDestinationInstance:chatData forEntityMapping:mapping];

    return YES;
}

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject*)dInstance entityMapping:(NSEntityMapping*)mapping manager:(NSMigrationManager*)manager error:(NSError**)error
{
    return YES;
}

@end
