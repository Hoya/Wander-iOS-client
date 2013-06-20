//
//  SendPhotoOperation.m
//  Wander
//
//  Created by Jiho Kang on 9/12/11.
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

#import "QueuePhotoOperation.h"
#import "UtilityClasses.h"

@implementation QueuePhotoOperation
@synthesize matchData;
@synthesize insertedChatData;
@synthesize insertedImageData;
@synthesize key;
@synthesize metaData;
@synthesize image;
@synthesize thumbnailImage;
@synthesize saveToCameraRoll;

- (id)initWithMatchData:(MatchData*)data withKey:(NSString*)messageKey andImage:(UIImage*)imageData saveToCameralRoll:(bool)shouldSave
{
    self = [super init];
    
    if(self != nil)
    {
        if(data == nil || imageData == nil || messageKey == nil)
        {
            [self release];
            return nil;
        }
        
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        
        context = [[ThreadMOC alloc] init];

        self.matchData = (MatchData*)[context objectWithID:[data objectID]];
        matchNo = [[self.matchData valueForKey:@"matchNo"] intValue];
        partnerNo = [[self.matchData valueForKey:@"partnerNo"] intValue];
        
        self.key = messageKey;

        self.image = imageData;
        self.saveToCameraRoll = [NSNumber numberWithBool:shouldSave];
    }
    
    return self;
}

- (void)dealloc
{
    self.matchData = nil;
    self.insertedChatData = nil;
    self.insertedImageData = nil;
    self.key = nil;
    self.metaData = nil;
    self.image = nil;
    self.thumbnailImage = nil;
    self.saveToCameraRoll = nil;
    [context release];
    [super dealloc];
}

- (void)main
{
    @try
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        if([self isCancelled] == NO)
        {
            [self preparePhoto];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"shouldDismissModalView" object:nil];
            
            [self queuePhoto];

            // save image to camera roll
            if([self.saveToCameraRoll boolValue] == YES)
            {
                [self performSelector:@selector(saveImageToCameraRoll)];
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

# pragma mark - photo delivery methods
- (void)saveImageToCameraRoll
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    [pool drain];
}

// register message id for photo delivery
- (void)preparePhoto
{
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    
    // create thumbnail for image
    double height = 0;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
    {   
        height = calcHeightFromWidth(self.image.size.width, self.image.size.height, 370);
        self.thumbnailImage = [self.image resizedImage:CGSizeMake(370, height) interpolationQuality:kCGInterpolationLow];
    }
    else
    {
        height = calcHeightFromWidth(self.image.size.width, self.image.size.height, 185);
        self.thumbnailImage = [self.image resizedImage:CGSizeMake(185, height) interpolationQuality:kCGInterpolationLow];
    }
    
    // save in core data
	self.insertedChatData = [NSEntityDescription insertNewObjectForEntityForName:@"ChatData" inManagedObjectContext:context];
    
	// set key for message
	[insertedChatData setKey:self.key];
    
	// set matchNo
	[insertedChatData setMatchNo:[NSNumber numberWithInt:matchNo]];
    
	// set sender
	[insertedChatData setSender:[NSNumber numberWithInt:[appDelegate.prefs integerForKey:@"memberNo"]]];
    
	// set receiver
	[insertedChatData setReceiver:[NSNumber numberWithInt:partnerNo]];
    
	// set image bool
	[insertedChatData setIsImage:[NSNumber numberWithBool:YES]];
    
	// set status
	[insertedChatData setStatus:[NSNumber numberWithInt:1]];
    
    // set match data relationship
	[insertedChatData setMatchData:self.matchData];
    
    // new image object
    self.insertedImageData = [NSEntityDescription insertNewObjectForEntityForName:@"ImageData" inManagedObjectContext:context];
    [insertedImageData setKey:self.key];
    
    // set chat data relationship
    [insertedImageData setChatData:insertedChatData];
    
    // save core data:
	[appDelegate saveContext:context];

    // add to upload pool
    NSMutableDictionary *objectInfo = [NSMutableDictionary dictionary];
    [objectInfo setValue:[self.insertedChatData objectID] forKey:@"objectID"];
    [objectInfo setValue:self.key forKey:@"key"];
    [dnc postNotificationName:@"shouldAddToUploadPool" object:nil userInfo:objectInfo];

    // set cache for photo
    [dnc postNotificationName:@"shouldSetPhotoCache" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.thumbnailImage, @"photo", key, @"key", nil]];
    
    // scroll to bottom
    [dnc postNotificationName:@"shouldScrollToBottomAnimated" object:nil];
}

// queue photo for delivery, resize and add image to core data
- (void)queuePhoto
{
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];

    [context refreshObject:self.insertedImageData mergeChanges:YES];
    
	// compress image
	double height = calcHeightFromWidth(self.image.size.width, self.image.size.height, 960);
	UIImage *resizedImage = [self.image resizedImage:CGSizeMake(960, height) interpolationQuality:kCGInterpolationDefault];

    NSData *compressedImageData = UIImageJPEGRepresentation(resizedImage, 0.2);
    NSString *imageFile = [UtilityClasses saveImageData:compressedImageData named:@"image" withKey:self.key overwrite:YES];
    [insertedImageData setValue:imageFile forKey:@"imageFile"];

    // set location data
    if([self.metaData count] > 0)
    {
        [insertedImageData setValue:[self.metaData valueForKey:@"missionNo"] forKey:@"missionNo"];
        [insertedImageData setValue:[self.metaData valueForKey:@"mission"] forKey:@"mission"];
        
        [insertedImageData setValue:[self.metaData valueForKey:@"caption"] forKey:@"caption"];
        
        [insertedImageData setValue:[self.metaData valueForKey:@"latitude"] forKey:@"latitude"];
        [insertedImageData setValue:[self.metaData valueForKey:@"longitude"] forKey:@"longitude"];
        
        [insertedImageData setValue:[self.metaData valueForKey:@"cityName"] forKey:@"cityName"];
        if([self.metaData valueForKey:@"provinceName"])
        {
            [insertedImageData setValue:[self.metaData valueForKey:@"provinceName"] forKey:@"provinceName"];
        }
        if([self.metaData valueForKey:@"provinceCode"])
        {
            [insertedImageData setValue:[self.metaData valueForKey:@"provinceCode"] forKey:@"provinceCode"];
        }
        [insertedImageData setValue:[self.metaData valueForKey:@"countryName"] forKey:@"countryName"];
        [insertedImageData setValue:[self.metaData valueForKey:@"countryCode"] forKey:@"countryCode"];
        
        if([self.metaData valueForKey:@"locationName"])
        {
            [insertedImageData setValue:[self.metaData valueForKey:@"locationName"] forKey:@"locationName"];
        }
        
        if([self.metaData valueForKey:@"locationId"])
        {
            [insertedImageData setValue:[self.metaData valueForKey:@"locationId"] forKey:@"locationId"];
        }
        
        NSNumber *captionHeight = [NSNumber numberWithFloat:0];
        if(![[self.metaData valueForKey:@"caption"] isEqualToString:@""] && [self.metaData valueForKey:@"caption"] != nil)
        {
            NSString *captionText = [self.metaData valueForKey:@"caption"];
            CGSize captionBounds = {180.0f, 99999.0f};		// width and height of text area
            CGSize captionSize = [captionText sizeWithFont:[UIFont fontWithName:NSLocalizedString(@"font", nil) size:14.0] constrainedToSize:captionBounds lineBreakMode:UILineBreakModeWordWrap];
            captionHeight = [NSNumber numberWithFloat:captionSize.height];
        }
        
        [insertedImageData setValue:captionHeight forKey:@"captionHeight"];
    }
    else
    {
        [insertedImageData setValue:[NSNumber numberWithFloat:0] forKey:@"captionHeight"];
    }
    
    [appDelegate saveContext:context];

    NSDictionary *thumbnailData = [NSDictionary dictionaryWithObjectsAndKeys:UIImageJPEGRepresentation(self.thumbnailImage, 0.4), @"thumbnail", self.key, @"key", nil];
    [dnc postNotificationName:@"shouldSetThumbnail" object:nil userInfo:thumbnailData];
    [dnc postNotificationName:@"shouldScrollToBottomAnimated" object:nil];
}

#pragma mark - save to camera roll delegate
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
	// Was there an error?
	if (error != NULL)
	{
		// Show error message...
		NSLog(@"error saving to camera roll: %@", error);
    }
}

@end
