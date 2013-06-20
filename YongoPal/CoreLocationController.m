//
//  CoreLocationController.m
//  YongoPal
//
//  Created by Jiho Kang on 4/12/11.
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

#import "CoreLocationController.h"


@implementation CoreLocationController
@synthesize locationManager, delegate;

- (id)init
{
	self = [super init];
	
	if(self != nil)
    {
        locationManager = [[CLLocationManager alloc] init]; // Create new instance of locMgr
        locationManager.delegate = self; // Set the delegate as self.
	}
	
	return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // Check if the class assigning itself as the delegate conforms to our protocol.  If not, the message will go nowhere.  Not good.
	if([self.delegate conformsToProtocol:@protocol(CoreLocationControllerDelegate)])
    {  
		[self.delegate locationUpdate:newLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // Check if the class assigning itself as the delegate conforms to our protocol.  If not, the message will go nowhere.  Not good.
	if([self.delegate conformsToProtocol:@protocol(CoreLocationControllerDelegate)]) 
    {
        [self.delegate locationError:error];
	}
}

- (void)dealloc
{
	[locationManager release];
	[super dealloc];
}

@end
