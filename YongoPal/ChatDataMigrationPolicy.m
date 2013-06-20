//
//  ChatDataMigrationPolicy.m
//  Wander
//
//  Created by Jiho Kang on 9/14/11.
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

#import "ChatDataMigrationPolicy.h"

@implementation ChatDataMigrationPolicy

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    // Create the managed object
    NSManagedObject *chatData = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName] inManagedObjectContext:[manager destinationContext]];
    
    [chatData setValue:[sInstance valueForKey:@"status"] forKey:@"status"];
    [chatData setValue:[sInstance valueForKey:@"sender"] forKey:@"sender"];
    [chatData setValue:[sInstance valueForKey:@"messageNo"] forKey:@"messageNo"];
    [chatData setValue:[sInstance valueForKey:@"datetime"] forKey:@"datetime"];
    [chatData setValue:[sInstance valueForKey:@"receiver"] forKey:@"receiver"];
    [chatData setValue:[sInstance valueForKey:@"message"] forKey:@"message"];
    [chatData setValue:[sInstance valueForKey:@"key"] forKey:@"key"];
    [chatData setValue:[sInstance valueForKey:@"isImage"] forKey:@"isImage"];
    [chatData setValue:[sInstance valueForKey:@"missionNo"] forKey:@"missionNo"];
    [chatData setValue:[sInstance valueForKey:@"matchNo"] forKey:@"matchNo"];

    // create image directory
    NSFileManager *fileManager= [NSFileManager defaultManager]; 
    NSString *imagesDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Images"];
    BOOL isDir;
    if(![fileManager fileExistsAtPath:imagesDirectory isDirectory:&isDir])
    {
        if(![fileManager createDirectoryAtPath:imagesDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
        {
            NSLog(@"Error: Create folder failed %@", imagesDirectory);
        }
    }
    
    // set text width and height
    float textHeight = 0;
    float textWidth = 0;
    if([sInstance valueForKey:@"message"] != nil)
	{
        NSString *messageText = [sInstance valueForKey:@"message"];
		CGSize textSize = {180.0f, 99999.0f};		// width and height of text area
		CGSize size = [messageText sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
		textHeight = size.height;
        textWidth = size.width;
	}

    [chatData setValue:[NSNumber numberWithFloat:textHeight] forKey:@"textHeight"];
    [chatData setValue:[NSNumber numberWithFloat:textWidth] forKey:@"textWidth"];
    
    NSString *thumbnailFile = [NSString stringWithFormat:@"Documents/Images/%@_thumbnail.jpg", [sInstance valueForKey:@"key"]];
    NSString *thumbnailPath = [NSHomeDirectory() stringByAppendingPathComponent:thumbnailFile];
    
    if([sInstance valueForKey:@"thumbnailData"] != nil)
    {
        NSData *jpegData = [sInstance valueForKey:@"thumbnailData"];
        [jpegData writeToFile:thumbnailPath atomically:YES];
    }
    else
    {
        thumbnailFile = nil;
    }

    [chatData setValue:thumbnailFile forKey:@"thumbnailFile"];

    // Set up the association for the migration manager
    [manager associateSourceInstance:sInstance withDestinationInstance:chatData forEntityMapping:mapping];

    return YES;
}

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject*)dInstance entityMapping:(NSEntityMapping*)mapping manager:(NSMigrationManager*)manager error:(NSError**)error
{
    return YES;
}

@end
