//
//  MissionViewControllerOld.h
//  YongoPal
//
//  Created by Jiho Kang on 5/17/11.
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

#import <UIKit/UIKit.h>
#import "YongoPalAppDelegate.h"
#import "SharePhotoController.h"
#import "MissionCell.h"
#import "MatchData.h"
#import "MissionData.h"

@protocol MissionViewOldDelegate
- (void)pushShareControllerWithData:(NSDictionary*)data;
@end

@interface MissionViewControllerOld : UIViewController
<
	UITableViewDataSource,
	UITableViewDelegate,
	UIActionSheetDelegate,
	NSFetchedResultsControllerDelegate,
	UINavigationControllerDelegate,
	UIImagePickerControllerDelegate
>
{
	YongoPalAppDelegate *appDelegate;
    NSOperationQueue *operationQueue;
    MatchData *matchData;
	id <MissionViewOldDelegate> delegate;
	UITableView *_tableView;
	NSFetchedResultsController *resultsController;
	NSString *viewTitle;
	NSIndexPath *selectedMission;
	NSDate *todayUTC;
    NSNumber *selectedMissionNo;
    UIView *highlightView;

    int matchNo;
	bool firstRun;
    UIInterfaceOrientation currentOrientation;
}

@property (nonatomic, retain) MatchData *matchData;
@property (nonatomic, assign) id <MissionViewOldDelegate> delegate;
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) IBOutlet UITableView *_tableView;
@property (nonatomic, retain) NSString *viewTitle;
@property (nonatomic, retain) NSIndexPath *selectedMission;
@property (nonatomic, retain) NSDate *todayUTC;
@property (nonatomic, retain) NSNumber *selectedMissionNo;
@property (nonatomic, retain) IBOutlet UIView *highlightView;
@property (nonatomic, readwrite) int matchNo;
@property (nonatomic, readwrite) bool firstRun;

- (bool)hasNewMissions;
- (void)checkNewMissions;
- (void)goBack;
- (void)getMissions:(int)matchNumber;
- (void)getMissionsFromServer;
- (void)saveImageToCameraRoll:(UIImage*)image;
- (void)logMission:(MissionData*)missionData;
- (void)highlightMission:(NSIndexPath*)indexPath;
- (void)unhighlightMission;
- (CGFloat)getTextHeight:(NSIndexPath *)indexPath forWidth:(float)width;

@end
