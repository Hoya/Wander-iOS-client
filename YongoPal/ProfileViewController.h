//
//  ProfileViewController.h
//  YongoPal
//
//  Created by Jiho Kang on 4/13/11.
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
#import "CoreLocationController.h"
#import "ProfileDataCell.h"
#import "LocationPickerViewController.h"

@interface ProfileViewController : UIViewController
<
	UITableViewDelegate,
	UITableViewDataSource,
	UIAlertViewDelegate,
	UIActionSheetDelegate,
	UIImagePickerControllerDelegate,
	UINavigationControllerDelegate,
	UIPickerViewDelegate,
	UITextFieldDelegate,
	LocationPickerDeleagte,
	CoreLocationControllerDelegate,
	ProfileDataCellDelegate,
    APIRequestDelegate
>
{
	YongoPalAppDelegate *appDelegate;
    NSOperationQueue *operationQueue;
	CoreLocationController *CLController;
	NSMutableArray *listOfItems;
	NSMutableArray *headers;

	// xib elements
	UITableView *_tableView;
	UIImageView *profileImage;
	UIView *imagePlaceholder;
	UILabel *nameLabel;
	UISegmentedControl *genderControl;
	UIToolbar *datePickerToolbar;
	UIDatePicker *datePicker;
	
	// temporary values
	NSString *cityNameValue;
	NSString *provinceNameValue;
	NSString *provinceCodeValue;
	NSString *countryNameValue;
	NSString *countryCodeValue;
	NSString *timezoneValue;
	NSDate *birthdayValue;
	NSString *introValue;
    float latitude;
    float longitude;

    id activeField;
	bool firstSignup;
	bool isModalView;
	bool keyboardVisible;
	bool birthdayPickerVisible;
	bool countryPickerVisible;
	CGPoint offset;
}

@property (nonatomic, retain) CoreLocationController *CLController;
@property (nonatomic, retain) NSMutableArray *listOfItems;
@property (nonatomic, retain) NSMutableArray *headers;

@property (nonatomic, retain) IBOutlet UITableView *_tableView;
@property (nonatomic, retain) IBOutlet UIImageView *profileImage;
@property (nonatomic, retain) IBOutlet UIView *imagePlaceholder;
@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UISegmentedControl *genderControl;
@property (nonatomic, retain) IBOutlet UIToolbar *datePickerToolbar;
@property (nonatomic, retain) UIDatePicker *datePicker;

@property (nonatomic, retain) NSString *cityNameValue;
@property (nonatomic, retain) NSString *provinceNameValue;
@property (nonatomic, retain) NSString *provinceCodeValue;
@property (nonatomic, retain) NSString *countryNameValue;
@property (nonatomic, retain) NSString *countryCodeValue;
@property (nonatomic, retain) NSString *timezoneValue;
@property (nonatomic, retain) NSDate *birthdayValue;
@property (nonatomic, retain) NSString *introValue;
@property (nonatomic, readwrite) float latitude;
@property (nonatomic, readwrite) float longitude;

@property (nonatomic, assign) id activeField;
@property (nonatomic, readwrite) bool firstSignup;
@property (nonatomic, readwrite) bool isModalView;
@property (nonatomic, readwrite) CGPoint offset;

- (void)keepAlive:(NSNumber *)fromBackground;
- (void)setBirthday;
- (IBAction)doneSettingBirthday;
- (void)setCountry;
- (void)showLocationPicker;
- (void)skipEditProfile;
- (void)doneSettingProfile;
- (void)saveProfile;
- (IBAction)pickProfileImage;
- (void)setProfileData;
- (void)setLocationData;
- (void)setIntro;
- (void)goBack;
- (void)saveProfileImage:(UIImage*)image;
- (void)deleteImage;
- (void)deleteImageOnServer;
- (void)scrollToRow:(NSNumber *)row;
- (ProfileDataCell *)getProfileCell:(NSNumber *)row;

@end
