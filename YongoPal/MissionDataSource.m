//
//  MissionDataSource.m
//  YongoPal
//
//  Created by Jiho Kang on 6/27/11.
//  Copyright 2011 BetaStudios, Inc. All rights reserved.
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

#import "MissionDataSource.h"
#import "MissionData.h"

@implementation MissionDataSource
@synthesize resultsController;
@synthesize matchNo;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		appDelegate = (YongoPalAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // create managed object context
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator:[appDelegate persistentStoreCoordinator]];
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc addObserver:self selector:@selector(mergeContextChanges:) name:NSManagedObjectContextDidSaveNotification object:appDelegate.managedObjectContext];
	}
	return self;
}

- (id)initWithMatchNo:(int)matchNumber
{
	self = [self init];
	self.matchNo = matchNumber;
	[self checkNewMissions];
	return self;
}

- (void)initTodaysMissionPages
{
	self.resultsController = [self getMissions:matchNo fromDate:[NSDate date]];
}

- (NSInteger)numDataPages
{
	return [[self.resultsController sections] count];
}

- (NSDictionary*)dataForPage:(NSInteger)pageIndex
{
	return [[self.resultsController sections] objectAtIndex:pageIndex];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [context release];
    
    self.resultsController = nil;
	[resultsController release];
    [super dealloc];
}

- (void)checkNewMissions
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
	[dateFormatter setTimeZone:timeZone];
	[dateFormatter setDefaultDate:[NSDate date]];
	NSDate *todayUTC = [dateFormatter defaultDate];
	[dateFormatter release];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"MissionData" inManagedObjectContext:context];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo == %d", matchNo]];
	NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"date == %@", todayUTC];
	[request setPredicate:predicate];
	[request setPredicate:predicate2];
	
	NSError *error = nil;
	NSUInteger count = [context countForFetchRequest:request error:&error];
	[request release];
	
	if(count == 0)
	{
		[self performSelectorInBackground:@selector(getMissionsFromServer) withObject:nil];
	}
}

- (NSFetchedResultsController*)getMissions:(int)matchNumber fromDate:(NSDate*)date
{
	NSString *sectionKey = @"date";

	NSFetchRequest *missionDataRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"MissionData" inManagedObjectContext:context];
	[missionDataRequest setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo = %d", matchNo]];
	[missionDataRequest setPredicate:predicate];
	
	if(date != nil)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
		[dateFormatter setTimeZone:timeZone];
		[dateFormatter setDefaultDate:[NSDate date]];
		NSDate *todayUTC = [dateFormatter defaultDate];
		[dateFormatter release];
									 
		NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"date == %@", todayUTC];
		[missionDataRequest setPredicate:predicate2];

		sectionKey = @"missionNo";
	}
	
	NSSortDescriptor *sortDescripter = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	NSArray *sortDescripters = [[NSArray alloc] initWithObjects:sortDescripter, nil];
	[missionDataRequest setSortDescriptors:sortDescripters];
	[sortDescripters release];
	[sortDescripter release];
	
	[missionDataRequest setFetchLimit:35];
	
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] 
															initWithFetchRequest:missionDataRequest 
															managedObjectContext:context
															sectionNameKeyPath:sectionKey
															cacheName:[NSString stringWithFormat:@"%d_mission.cache", matchNumber]];
	[missionDataRequest release];
	
	fetchedResultsController.delegate = self;
	NSError *error;
	BOOL success = [fetchedResultsController performFetch:&error];
	if(!success)
	{
		NSLog(@"setMissionList error: %@", error);
	}
	return [fetchedResultsController autorelease];
}

- (void)getMissionsFromServer
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
	NSString *memberNoString = [NSString stringWithFormat:@"%d", [appDelegate.prefs integerForKey:@"memberNo"]];
	[requestData setValue:memberNoString forKey:@"memberNo"];
	[requestData setValue:[NSNumber numberWithInt:matchNo] forKey:@"matchNo"];
	
	NSDictionary *results = [appDelegate.apiRequest sendServerRequest:@"mission" withTask:@"getNewMissions" withData:requestData];
    if(results)
    {
        [self performSelectorOnMainThread:@selector(setMissions:) withObject:results waitUntilDone:YES];
    }
	[requestData release];
	[pool drain];
}

- (void)setMissions:(NSDictionary*)missions
{
	if([missions count] > 0)
	{
		for(NSDictionary *missionData in missions)
		{
			NSFetchRequest *request = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"MissionData" inManagedObjectContext:context];
			[request setEntity:entity];
			
			NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"matchNo == %d AND missionNo == %d", matchNo, [[missionData valueForKey:@"missionNo"] intValue]]];
			[request setPredicate:predicate];
			
			NSError *error;
			NSUInteger count = [context countForFetchRequest:request error:&error];
			[request release];
			
			if(count == 0)
			{
				NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"MissionData" inManagedObjectContext:context];
				
				// set matchNo
				[newManagedObject setValue:[NSNumber numberWithInt:matchNo] forKey:@"matchNo"];
				
				// set missionNo
				[newManagedObject setValue:[NSNumber numberWithInt:[[missionData valueForKey:@"missionNo"] intValue]] forKey:@"missionNo"];
				
				// set mission description
				[newManagedObject setValue:[missionData valueForKey:@"description"] forKey:@"mission"];
				
				// set date
				NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
				[formatter setDateFormat:@"yyyy-MM-dd"];
				NSDate *date = [formatter dateFromString:[missionData valueForKey:@"date"]];
				[newManagedObject setValue:date forKey:@"date"];
				[formatter release];
				
				// set check
				if([missionData valueForKey:@"checkDatetime"] != [NSNull null])
				{
					[newManagedObject setValue:[NSNumber numberWithBool:YES] forKey:@"check"];
				}			
				
				// save
				[appDelegate saveContext:context];
			}
		}
	}
}

- (void)mergeContextChanges:(NSNotification *)notification
{
    SEL selector = @selector(mergeChangesFromContextDidSaveNotification:);
    [context performSelectorOnMainThread:selector withObject:notification waitUntilDone:YES];
    
    [self performSelectorOnMainThread:@selector(controllerDidChangeContent:) withObject:self.resultsController waitUntilDone:NO];
}

@end
