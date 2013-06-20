//
//  LocationPickerViewController.h
//  YongoPal
//
//  Created by Jiho Kang on 6/20/11.
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

@protocol LocationPickerDeleagte <NSObject>
- (void)setLocationData;
- (void)setCityNameValue:(NSString*)value;
- (void)setProvinceNameValue:(NSString*)value;
- (void)setProvinceCodeValue:(NSString*)value;
- (void)setCountryNameValue:(NSString*)value;
- (void)setCountryCodeValue:(NSString*)value;
- (void)setTimezoneValue:(NSString*)value;
- (void)setLatitude:(float)value;
- (void)setLongitude:(float)value;
@end

@interface LocationPickerViewController : UIViewController
<
	UISearchDisplayDelegate,
	UISearchBarDelegate,
	UITableViewDataSource,
	UITableViewDelegate,
	UIAlertViewDelegate,
	UIActionSheetDelegate
>
{
	YongoPalAppDelegate *appDelegate;
	NSMutableArray *locationData;
	SBJsonParser *jsonParser;
	
	id <LocationPickerDeleagte> delegate;
	
	NSString *cityName;
	NSString *provinceName;
	NSString *provinceCode;
	NSString *countryName;
	NSString *countryCode;
	NSString *timezone;
    float latitude;
    float longitude;
	
	NSOperationQueue *operationQueue;
}

@property (nonatomic, assign) id <LocationPickerDeleagte> delegate;
@property (nonatomic, retain) NSString *cityName;
@property (nonatomic, retain) NSString *provinceName;
@property (nonatomic, retain) NSString *provinceCode;
@property (nonatomic, retain) NSString *countryName;
@property (nonatomic, retain) NSString *countryCode;
@property (nonatomic, retain) NSString *timezone;

- (void)cancelLocation;
- (void)searchOperation:(NSTimer*)timer;
- (void)mockSearch:(NSString*)queryString;

@end
