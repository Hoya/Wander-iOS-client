//
//  IntroViewController.h
//  YongoPal
//
//  Created by Jiho Kang on 6/28/11.
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
#import "PageControl.h"


@interface IntroViewController : UIViewController
<
	UIScrollViewDelegate,
	PageControlDelegate
>
{
	UIScrollView *scrollView;
	PageControl *_pageControl;
	UIView *intro1;
	UIView *intro2;
	UIView *intro3;
	UIView *intro4;
	UIView *intro5;
    
    UILabel *introTitle1;
	UILabel *introTitle2;
	UILabel *introTitle3;
	UILabel *introTitle4;
	UILabel *introTitle5;
    
    UILabel *introSub1;
    UILabel *introSub2;
    UILabel *introSub3;
    UILabel *introSub4;
    UILabel *introSub5;
	
	UIView *currentPage;
	UIView *nextPage;
	
	UIImageView *backButton;
	UIImageView *forwardButton;
	UIButton *startButton;
    UIButton *completeProfileButton;
	
	int currentPageNumber;
    bool shouldShowProfile;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet PageControl *_pageControl;
@property (nonatomic, retain) IBOutlet UIView *intro1;
@property (nonatomic, retain) IBOutlet UIView *intro2;
@property (nonatomic, retain) IBOutlet UIView *intro3;
@property (nonatomic, retain) IBOutlet UIView *intro4;
@property (nonatomic, retain) IBOutlet UIView *intro5;

@property (nonatomic, retain) IBOutlet UILabel *introTitle1;
@property (nonatomic, retain) IBOutlet UILabel *introTitle2;
@property (nonatomic, retain) IBOutlet UILabel *introTitle3;
@property (nonatomic, retain) IBOutlet UILabel *introTitle4;
@property (nonatomic, retain) IBOutlet UILabel *introTitle5;

@property (nonatomic, retain) IBOutlet UILabel *introSub1;
@property (nonatomic, retain) IBOutlet UILabel *introSub2;
@property (nonatomic, retain) IBOutlet UILabel *introSub3;
@property (nonatomic, retain) IBOutlet UILabel *introSub4;
@property (nonatomic, retain) IBOutlet UILabel *introSub5;

@property (nonatomic, retain) IBOutlet UIImageView *backButton;
@property (nonatomic, retain) IBOutlet UIImageView *forwardButton;
@property (nonatomic, retain) IBOutlet UIButton *startButton;
@property (nonatomic, retain) IBOutlet UIButton *completeProfileButton;

@property (nonatomic, readwrite) bool shouldShowProfile;

- (void)goBack;
- (void)applyNewIndex:(NSInteger)newIndex pageView:(UIView *)pageView;
- (IBAction)changePage:(id)sender;
- (IBAction)showProfile;

@end