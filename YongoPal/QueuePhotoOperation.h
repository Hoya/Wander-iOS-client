//
//  QueuePhotoOperation.h
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

#import <Foundation/Foundation.h>
#import "YongoPalAppDelegate.h"
#import "MatchData.h"
#import "ChatData.h"
#import "ImageData.h"

@interface QueuePhotoOperation : NSOperation
{
    YongoPalAppDelegate *appDelegate;

    NSManagedObjectContext *context;
    
    MatchData *matchData;
    ChatData *insertedChatData;
    ImageData *insertedImageData;
    NSString *key;
    NSDictionary *metaData;
    
    UIImage *image;
    UIImage *thumbnailImage;
    NSNumber *saveToCameraRoll;
    
    int matchNo;
    int partnerNo;
    bool resendMessage;
}

@property (nonatomic, retain) MatchData *matchData;
@property (nonatomic, retain) ChatData *insertedChatData;
@property (nonatomic, retain) ImageData *insertedImageData;
@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSDictionary *metaData;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIImage *thumbnailImage;
@property (nonatomic, retain) NSNumber *saveToCameraRoll;

- (id)initWithMatchData:(MatchData*)data withKey:(NSString*)messageKey andImage:(UIImage*)imageData saveToCameralRoll:(bool)shouldSave;
- (void)saveImageToCameraRoll;
- (void)preparePhoto;
- (void)queuePhoto;

@end
