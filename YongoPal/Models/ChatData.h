//
//  ChatData.h
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ImageData, MatchData, TranslationData;

@interface ChatData : NSManagedObject

@property (nonatomic, retain) NSNumber * missionNo;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSNumber * textHeight;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSNumber * receiver;
@property (nonatomic, retain) NSString * thumbnailFile;
@property (nonatomic, retain) NSNumber * isImage;
@property (nonatomic, retain) NSString * detectedLanguage;
@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSNumber * messageNo;
@property (nonatomic, retain) NSNumber * matchNo;
@property (nonatomic, retain) NSNumber * sender;
@property (nonatomic, retain) NSDate * datetime;
@property (nonatomic, retain) NSNumber * textWidth;
@property (nonatomic, retain) ImageData *imageData;
@property (nonatomic, retain) MatchData *matchData;
@property (nonatomic, retain) NSSet *translationData;
@end

@interface ChatData (CoreDataGeneratedAccessors)

- (void)addTranslationDataObject:(TranslationData *)value;
- (void)removeTranslationDataObject:(TranslationData *)value;
- (void)addTranslationData:(NSSet *)values;
- (void)removeTranslationData:(NSSet *)values;
@end
