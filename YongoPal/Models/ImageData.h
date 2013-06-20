//
//  ImageData.h
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

@class ChatData;

@interface ImageData : NSManagedObject

@property (nonatomic, retain) NSNumber * missionNo;
@property (nonatomic, retain) NSString * locationName;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * countryName;
@property (nonatomic, retain) NSString * cityName;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * locationId;
@property (nonatomic, retain) NSString * imageFile;
@property (nonatomic, retain) NSNumber * messageNo;
@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * countryCode;
@property (nonatomic, retain) NSString * provinceCode;
@property (nonatomic, retain) NSString * provinceName;
@property (nonatomic, retain) NSNumber * captionHeight;
@property (nonatomic, retain) NSString * mission;
@property (nonatomic, retain) ChatData *chatData;

@end
