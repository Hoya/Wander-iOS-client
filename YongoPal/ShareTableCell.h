//
//  ShareTableCell.h
//  Wander
//
//  Created by Jiho Kang on 9/19/11.
//  Copyright 2011 YongoPal, Inc. All rights reserved.
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

@protocol ShareTableCellDelegate
- (void)didTouchSwitch:(id)sender;
@end

@interface ShareTableCell : UITableViewCell
{
    id <ShareTableCellDelegate> delegate;
    IBOutlet UILabel *shareLabel;
    IBOutlet UISwitch *shareSwitch;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UIImageView *arrowImage;
    IBOutlet UILabel *configureLabel;
    IBOutlet UIImageView *iconImage;
}

@property(nonatomic, assign) id <ShareTableCellDelegate> delegate;
@property(nonatomic, retain) UILabel *shareLabel;
@property(nonatomic, retain) UISwitch *shareSwitch;
@property(nonatomic, retain) UIActivityIndicatorView *spinner;
@property(nonatomic, retain) UIImageView *arrowImage;
@property(nonatomic, retain) UILabel *configureLabel;
@property(nonatomic, retain) UIImageView *iconImage;

- (IBAction)didTouchSwitch:(id)sender;

@end
