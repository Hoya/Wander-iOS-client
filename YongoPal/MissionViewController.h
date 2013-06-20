//
//  MissionViewController.h
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

#import <UIKit/UIKit.h>
#import "YongoPalAppDelegate.h"
#import "MissionDataSource.h"
#import	"PreviewPhotoController.h"
#import "MissionCell.h"

@protocol MissionViewDelegate
- (void)preparePhoto:(UIImage*)photo;
@end

@interface MissionViewController : UIViewController
<
	UITableViewDataSource,
	UITableViewDelegate,
	UIActionSheetDelegate,
	NSFetchedResultsControllerDelegate,
	UINavigationControllerDelegate,
	UIImagePickerControllerDelegate
>
{
    NSInteger pageIndex;
	MissionDataSource *missionDataSource;
	
	YongoPalAppDelegate *appDelegate;
	id <MissionViewDelegate> delegate;
	UITableView *_tableView;
	NSFetchedResultsController *resultsController;
	NSString *viewTitle;
	NSIndexPath *selectedMission;
	
	int matchNo;
}
@property (nonatomic, assign) id <MissionViewDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITableView *_tableView;
@property (nonatomic, retain) MissionDataSource *missionDataSource;
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) NSString *viewTitle;
@property (nonatomic, retain) NSIndexPath *selectedMission;
@property (nonatomic, readwrite) NSInteger pageIndex;
@property (nonatomic, readwrite) int matchNo;

@end
