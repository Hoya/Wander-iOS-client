//
//  ChatCell.h
//  YongoPal
//
//  Created by Jiho Kang on 5/3/11.
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

@protocol ChatCellDelegate
- (void)showOptions:(NSIndexPath*)indexPath;
- (void)didTouchBackground;
- (void)didTouchThumbnail:(int)messageNo atIndex:(NSIndexPath*)indexPath;
@end

@interface ChatCell : UITableViewCell
{
	id <ChatCellDelegate> delegate;

	IBOutlet UIImageView *profileImage;
	IBOutlet UITextView *textMessage;
	IBOutlet UILabel *timeLabel;
	IBOutlet UIButton *errorButton;
	IBOutlet UIActivityIndicatorView *spinner;
	IBOutlet UIActivityIndicatorView *downloadSpinner;
	IBOutlet UIButton *imageButton;
	IBOutlet UIImageView *thumbnailImage;
	IBOutlet UIProgressView *progressView;
	
	int section;
	int nIndex;
	int messageNo;
	bool uploadRequestSent;
}

@property(nonatomic, assign) id <ChatCellDelegate> delegate;
@property(nonatomic, retain) UIImageView *profileImage;
@property(nonatomic, retain) UITextView *textMessage;
@property(nonatomic, retain) UILabel *timeLabel;
@property(nonatomic, retain) UIButton *errorButton;
@property(nonatomic, retain) UIActivityIndicatorView *spinner;
@property(nonatomic, retain) UIActivityIndicatorView *downloadSpinner;
@property(nonatomic, retain) UIButton *imageButton;
@property(nonatomic, retain) UIImageView *thumbnailImage;
@property(nonatomic, retain) UIProgressView *progressView;

@property(readwrite) int section;
@property(readwrite) int nIndex;
@property(readwrite) int messageNo;
@property(readwrite) bool uploadRequestSent;

- (IBAction)showOptions;
- (IBAction)didTouchBackground;
- (IBAction)didTouchThumbnail;
- (IBAction)didStartTouchingImage;
- (IBAction)didStopTouchingImage;
- (void)retainProgressView;
- (void)releaseProgressView;

@end
