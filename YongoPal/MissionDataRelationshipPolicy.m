//
//  MissionDataRelationshipPolicy.m
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

#import "MissionDataRelationshipPolicy.h"
#import "MatchData.h"

@implementation MissionDataRelationshipPolicy

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    // Create the managed object
    NSManagedObject *missionData = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName] inManagedObjectContext:[manager destinationContext]];
    
    [missionData setValue:[sInstance valueForKey:@"mission"] forKey:@"mission"];
    [missionData setValue:[sInstance valueForKey:@"check"] forKey:@"check"];
    [missionData setValue:[sInstance valueForKey:@"matchNo"] forKey:@"matchNo"];
    [missionData setValue:[sInstance valueForKey:@"date"] forKey:@"date"];
    [missionData setValue:[sInstance valueForKey:@"missionNo"] forKey:@"missionNo"];
    
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
        [missionData setValue:matchDataObject forKey:@"matchData"];
    }
    [matchRequest release];
    
    // Set up the association for the migration manager
    [manager associateSourceInstance:sInstance withDestinationInstance:missionData forEntityMapping:mapping];
    
    return YES;
}

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject*)dInstance entityMapping:(NSEntityMapping*)mapping manager:(NSMigrationManager*)manager error:(NSError**)error
{
    return YES;
}
@end
