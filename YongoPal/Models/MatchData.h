//
//  MatchData.h
//  Wander
//
//  Created by Jiho Kang on 2/7/12.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChatData, FeedbackData, MissionData;

@interface MatchData : NSManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * countryName;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSDate * expireDate;
@property (nonatomic, retain) NSNumber * timezoneOffset;
@property (nonatomic, retain) NSNumber * shouldShowIntro;
@property (nonatomic, retain) NSString * profileImage;
@property (nonatomic, retain) NSDate * lastMessageDatetime;
@property (nonatomic, retain) NSString * provinceCode;
@property (nonatomic, retain) NSString * intro;
@property (nonatomic, retain) NSNumber * profileImageNo;
@property (nonatomic, retain) NSNumber * partnerNo;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * update;
@property (nonatomic, retain) NSDate * regDatetime;
@property (nonatomic, retain) NSDate * birthday;
@property (nonatomic, retain) NSString * recentMessage;
@property (nonatomic, retain) NSNumber * muted;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * matchNo;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * countryCode;
@property (nonatomic, retain) NSString * isQuickMatch;
@property (nonatomic, retain) NSString * cityName;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSNumber * open;
@property (nonatomic, retain) NSString * timezone;
@property (nonatomic, retain) NSDate * activeDate;
@property (nonatomic, retain) NSDate * matchDatetime;
@property (nonatomic, retain) NSSet *chatData;
@property (nonatomic, retain) NSSet *missionData;
@property (nonatomic, retain) FeedbackData *feedbackData;
@end

@interface MatchData (CoreDataGeneratedAccessors)

- (void)addChatDataObject:(ChatData *)value;
- (void)removeChatDataObject:(ChatData *)value;
- (void)addChatData:(NSSet *)values;
- (void)removeChatData:(NSSet *)values;
- (void)addMissionDataObject:(MissionData *)value;
- (void)removeMissionDataObject:(MissionData *)value;
- (void)addMissionData:(NSSet *)values;
- (void)removeMissionData:(NSSet *)values;
@end
