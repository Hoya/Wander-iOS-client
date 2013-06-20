//
//  DebugViewController.h
//  YongoPal
//
//  Created by Jiho Kang on 5/16/11.
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
#import "ImageData.h"

@interface DebugViewController : UIViewController
<
	UITableViewDataSource,
	UITableViewDelegate,
	UIAlertViewDelegate,
    APIRequestDelegate
>
{
    YongoPalAppDelegate *appDelegate;
	NSMutableArray *listOfItems;
	UITableView *_tableView;
    UIView *loadingView;
    UIActivityIndicatorView *spinner;
    UIProgressView *progressView;
    UIProgressView *progressView2;
    UILabel *buildLabel;
    UILabel *loadingLabel;
    APIRequest *apiRequest;
    NSOperationQueue *receiveOperationQueue;
    NSMutableArray *downloadPool;
    float totalPhotos;
    float downloadProgress;
}

@property (nonatomic, retain) NSMutableArray *listOfItems;
@property (nonatomic, retain) IBOutlet UITableView *_tableView;
@property (nonatomic, retain) IBOutlet UILabel *buildLabel;
@property (nonatomic, retain) IBOutlet UIView *loadingView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView2;
@property (nonatomic, retain) IBOutlet UILabel *loadingLabel;
@property (nonatomic, retain) APIRequest *apiRequest;

- (void)sendDebugRequest:(NSString*)task withData:(NSDictionary*)requestData;
- (void)processResults:(NSDictionary*)results;
- (void)setProgressWithObject:(NSNumber*)progress;
- (void)processImportedChatData:(NSDictionary*)jsonObject;
- (void)goBack;
- (void)checkAccessCode:(NSString*)code;
- (void)pushToUnlockView;

- (void)clearChatData;
- (void)clearMatchData;
- (void)clearServerMatchData;
- (void)clearAllServerData;

- (ImageData*)getImageForKey:(NSString*)key withContext:(NSManagedObjectContext*)passedContext;
- (void)downloadThumbnail:(NSNumber*)messageNo;
- (void)setThumbnailData:(NSDictionary*)thumbnailData;

@end
