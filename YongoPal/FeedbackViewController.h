//
//  FeedbackViewController.h
//  YongoPal
//
//  Created by Jiho Kang on 7/1/11.
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
#import <QuartzCore/QuartzCore.h>
#import "YongoPalAppDelegate.h"
#import "MatchData.h"
#import "AnswerData.h"
#import "FeedbackCell.h"

@interface FeedbackViewController : UIViewController
<
	UITableViewDelegate,
	UITableViewDataSource,
	UITextViewDelegate,
	NSFetchedResultsControllerDelegate,
	FeedbackCellDelegate
>
{
	YongoPalAppDelegate *appDelegate;
    NSOperationQueue *operationQueue;
    MatchData *matchData;
	NSFetchedResultsController *resultsController;
	NSMutableArray *listOfItems;
    UITableView *_tableView;
	UITextView *otherFeedback;
    CGPoint offset;

	int checkedAnswer;
    AnswerData *checkedAnswerData;

	bool answerChecked;
	int declinedMatchNo;

    bool keyboardVisible;
    bool shouldReloadTable;
    bool viewIsLoaded;
}

@property(nonatomic, retain) MatchData *matchData;
@property(nonatomic, retain) IBOutlet UITableView *_tableView;
@property(nonatomic, retain) NSFetchedResultsController *resultsController;
@property(nonatomic, retain) NSMutableArray *listOfItems;
@property(nonatomic, retain) AnswerData *checkedAnswerData;
@property(readwrite) int declinedMatchNo;

- (void)updateFeedbackList;
- (NSFetchedResultsController*)getFeedbackList;
- (void)send;
- (void)cancel;
- (void)getFeedbackListFromServer;
- (void)setFeedbackFromServer:(NSDictionary*)feedbackList;

@end
