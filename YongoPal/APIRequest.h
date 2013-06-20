//
//  APIRequest.h
//  Wander
//
//  Created by Jiho Kang on 9/12/11.
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

#import <Foundation/Foundation.h>

@protocol APIRequestDelegate
@optional
- (void)didReceiveJson:(NSDictionary*)jsonObject andHeaders:(NSDictionary*)headers;
- (void)didReceiveBinary:(NSData*)data andHeaders:(NSDictionary*)headers;
- (void)apiRequestFailed:(NSDictionary*)errorData;
@end

#import "SBJson.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "ASIFormDataRequest.h"
#import "ASIDataCompressor.h"
#import "NSString+Urlencode.h"

@class YongoPalAppDelegate;
@interface APIRequest : NSObject <ASIHTTPRequestDelegate>
{
    YongoPalAppDelegate *appDelegate;
    ASINetworkQueue *downloadQueue;
    ASINetworkQueue *uploadQueue;
    id <APIRequestDelegate> delegate;

    NSString *apiHost;
    NSNumber *networkStatus;
    NSNumber *hostStatus;
    double threadPriority;
}

@property (nonatomic, assign) id <APIRequestDelegate> delegate;
@property (nonatomic, retain) ASINetworkQueue *downloadQueue;
@property (nonatomic, retain) ASINetworkQueue *uploadQueue;
@property (nonatomic, readwrite) double threadPriority;

+ (APIRequest*)sharedAPIRequest;
- (NSDictionary*)sendServerRequest:(NSString*)requestType withTask:(NSString*)task withData:(NSDictionary*)requestData;
- (void)sendAsyncServerRequest:(NSString *)requestType withTask:(NSString *)task withData:(NSDictionary *)requestData progressDelegate:(UIProgressView*)progressView;
- (NSData*)getSyncDataFromServer:(NSString *)type withTask:(NSString *)task withData:(NSDictionary *)requestData;
- (void)getAsyncDataFromServer:(NSString *)type withTask:(NSString *)task withData:(NSDictionary *)requestData progressDelegate:(UIProgressView*)progressView;
- (void)uploadImageFile:(NSString*)type withTask:(NSString*)task withImageData:(NSData*)data withData:(NSDictionary*)requestData progressDelegate:(UIProgressView*)progressView;
- (void)cancelAllAsyncOperations;
- (void)cancelAllSharedQueues;
- (void)cancelAllDownloads;
- (void)cancelAllUploads;
- (void)logApiResults:(NSDictionary*)data;

@end