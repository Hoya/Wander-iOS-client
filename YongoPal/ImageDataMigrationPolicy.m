//
//  ImageDataMigrationPolicy.m
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

#import "ImageDataMigrationPolicy.h"

@implementation ImageDataMigrationPolicy

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    // Create the managed object
    NSManagedObject *imageData = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName] inManagedObjectContext:[manager destinationContext]];
    
    [imageData setValue:[sInstance valueForKey:@"shared"] forKey:@"shared"];
    [imageData setValue:[sInstance valueForKey:@"messageNo"] forKey:@"messageNo"];
    [imageData setValue:[sInstance valueForKey:@"longitude"] forKey:@"longitude"];
    [imageData setValue:[sInstance valueForKey:@"latitude"] forKey:@"latitude"];
    [imageData setValue:[sInstance valueForKey:@"key"] forKey:@"key"];
    [imageData setValue:[sInstance valueForKey:@"type"] forKey:@"type"];
    [imageData setValue:[sInstance valueForKey:@"url"] forKey:@"url"];

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

    NSString *imageFile = [NSString stringWithFormat:@"Documents/Images/%@_image.jpg", [sInstance valueForKey:@"key"]];
    NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:imageFile];
    
    if([sInstance valueForKey:@"imageData"] != nil)
    {
        NSData *jpegData = [sInstance valueForKey:@"imageData"];
        [jpegData writeToFile:imagePath atomically:YES];
        
        [imageData setValue:imageFile forKey:@"imageFile"];
    }
    else
    {
        imageFile = nil;
    }
    
    [imageData setValue:imageFile forKey:@"imageFile"];

    // Set up the association for the migration manager
    [manager associateSourceInstance:sInstance withDestinationInstance:imageData forEntityMapping:mapping];

    return YES;
}

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject*)dInstance entityMapping:(NSEntityMapping*)mapping manager:(NSMigrationManager*)manager error:(NSError**)error
{
    return YES;
}

@end
