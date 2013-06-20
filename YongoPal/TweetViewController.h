//
//  TweetViewController.h
//  YongoPal
//
//  Created by Jiho Kang on 6/23/11.
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
#import "SA_OAuthTwitterEngine.h"
#import "SA_OAuthTwitterController.h"

@interface TweetViewController : UIViewController
<
	UITextViewDelegate,
    MGTwitterEngineDelegate,
	SA_OAuthTwitterEngineDelegate,
	SA_OAuthTwitterControllerDelegate
>
{
	YongoPalAppDelegate *appDelegate;
	SA_OAuthTwitterEngine *twitter;

    UIView *tweetContainer;
    UITextView *tweetText;
	UIView *bgView;
	UILabel *charCount;
	NSString *linkUrl;
    UILabel *linkLabel;
    UIImage *thumbnailImage;
    UIImageView *thumbnailView;
    NSString *imageKey;
	int matchNo;
    bool isOwner;
}
@property (nonatomic, retain) SA_OAuthTwitterEngine *twitter;
@property (nonatomic, retain) IBOutlet UIView *tweetContainer;
@property (nonatomic, retain) IBOutlet UITextView *tweetText;
@property (nonatomic, retain) IBOutlet UIView *bgView;
@property (nonatomic, retain) IBOutlet UILabel *charCount;
@property (nonatomic, retain) IBOutlet UILabel *linkLabel;
@property (nonatomic, retain) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, retain) NSString *linkUrl;
@property (nonatomic, retain) UIImage *thumbnailImage;
@property (nonatomic, retain) NSString *imageKey;
@property (nonatomic, readwrite) int matchNo;
@property (nonatomic, readwrite) bool isOwner;

- (void)cancel;
- (void)send;

@end
