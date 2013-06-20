//
//  APIRequest.m
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

#import "APIRequest.h"
#import "YongoPalAppDelegate.h"
#import "LFCGzipUtility.h"

@implementation APIRequest
@synthesize delegate;
@synthesize downloadQueue;
@synthesize uploadQueue;
@synthesize threadPriority;
static APIRequest *sharedAPIRequest;

+ (APIRequest*)sharedAPIRequest
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sharedAPIRequest = [[[APIRequest alloc] init] autorelease];
    }
    return sharedAPIRequest;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
        appDelegate = (YongoPalAppDelegate *) [[UIApplication sharedApplication] delegate];
        [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAllAsyncOperations) name:@"cancelAllAsyncOperations" object:nil];
        threadPriority = 0.5;
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelAllAsyncOperations];

    self.downloadQueue = nil;
    self.uploadQueue = nil;
    
    [downloadQueue release];
    [uploadQueue release];
    
    [super dealloc];
}

#pragma mark - ASIHTTPRequest
- (NSDictionary*)sendServerRequest:(NSString*)requestType withTask:(NSString*)task withData:(NSDictionary*)requestData
{    
	bool isError = NO;
    
	NSString *jsonRequestString = nil;
	if(requestData != nil)
	{
		SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
		jsonRequestString = [jsonWriter stringWithObject:requestData];
		[jsonWriter release];
	}
	[appDelegate didStartNetworking];
    
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/mobile/request.php", appDelegate.apiHost]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setThreadPriority:threadPriority];
    [request setAllowCompressedResponse:YES];
	[request setShouldWaitToInflateCompressedResponses:NO];
	[request setNumberOfTimesToRetryOnTimeout:2];
	[request setShouldAttemptPersistentConnection:YES];
	[request setPersistentConnectionTimeoutSeconds:30];
    [request setTimeOutSeconds:5];
    [request setUsername:@"yongopal"];
    [request setPassword:yongoApiKey];
    [request setValidatesSecureCertificate:NO];
    
	// set post data
	[request setPostValue:appDelegate.productionStage forKey:@"development"];
	if(requestType != nil) [request setPostValue:requestType forKey:@"type"];
	if(task != nil) [request setPostValue:task forKey:@"task"];
	if(jsonRequestString != nil) [request setPostValue:jsonRequestString forKey:@"data"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] intValue]] forKey:@"appVersion"];
	[request startSynchronous];
    
	NSError *error = [request error];
	NSMutableDictionary *apiResult = [[NSMutableDictionary alloc] init];
    
	int statusCode = [request responseStatusCode];
	NSString *json_string = [request responseString];
    NSDictionary *resultData = nil;
    
	if(error)
	{
		isError = YES;
        [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
	}
	else
	{
		if(statusCode == 200)
		{
			// process request data
			SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
			NSDictionary *jsonObject = (NSDictionary*)[jsonParser objectWithString:json_string error:nil];
			[jsonParser release];
            
			// check if data is valid json data
			if(jsonObject != nil || [jsonObject count] == 0)
			{
				[apiResult addEntriesFromDictionary:jsonObject];
				
				// check for api errors
				NSDictionary *serverError = [apiResult objectForKey:@"error"];
				if([serverError count] != 0)
				{
					isError = YES;
					NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Request Error", @"title", [serverError valueForKey:@"description"], @"message", nil];
					[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
					[alertContent release];
                    
                    [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
				}
                
                // check version
                double apiVersion = [[apiResult valueForKey:@"version"] doubleValue];
                double appVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] doubleValue];
                if(apiVersion > appVersion)
                {
					isError = YES;
					[appDelegate.mainNavController performSelectorOnMainThread:@selector(popToRootViewControllerAnimated:) withObject:nil waitUntilDone:NO];
					
					NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"API Error", @"title", @"This version is no longer supported.\nPlease download the latest version.", @"message", nil];
					[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
					[alertContent release];
					
					[apiResult setValue:nil forKey:@"result"];
                    
                    [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
                }
                
                resultData = (NSDictionary*)[apiResult objectForKey:@"result"];
			}
			else
			{
                [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
			}
		}
		else
		{
			isError = YES;
			NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"API Error", @"title", [NSString stringWithFormat:@"HTTP status code: %d for request type %@ and task %@", statusCode, requestType, task], @"message", nil];
			[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
            [alertContent release];
            [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
		}
	}
    [apiResult release];
	[appDelegate didStopNetworking];

    if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
    {
        // log results
        NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
        [logData setValue:appDelegate.apiHost forKey:@"server"];
        [logData setValue:requestType forKey:@"requestType"];
        [logData setValue:task forKey:@"task"];
        [logData setValue:jsonRequestString forKey:@"requestData"];
        [logData setValue:json_string forKey:@"resultData"];
        [logData setValue:[NSNumber numberWithBool:isError] forKey:@"isError"];
        [self performSelectorInBackground:@selector(logApiResults:) withObject:logData];
        [logData release];
    }

	return resultData;
}

- (void)sendAsyncServerRequest:(NSString *)requestType withTask:(NSString *)task withData:(NSDictionary *)requestData progressDelegate:(UIProgressView*)progressView
{
	NSString *jsonRequestString = nil;
	if(requestData != nil)
	{
		SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
		jsonRequestString = [jsonWriter stringWithObject:requestData];
		[jsonWriter release];
	}
	[appDelegate didStartNetworking];
    
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/mobile/request.php", appDelegate.apiHost]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setThreadPriority:threadPriority];
    [request setAllowCompressedResponse:YES];
	[request setShouldWaitToInflateCompressedResponses:NO];
	[request setNumberOfTimesToRetryOnTimeout:2];
	[request setShouldAttemptPersistentConnection:YES];
	[request setPersistentConnectionTimeoutSeconds:30];
    [request setTimeOutSeconds:10];
    [request setUsername:@"yongopal"];
    [request setPassword:yongoApiKey];
    [request setValidatesSecureCertificate:NO];
    [request setDelegate:self];
	[request setPostValue:appDelegate.productionStage forKey:@"development"];
	if(requestType != nil) [request setPostValue:requestType forKey:@"type"];
	if(task != nil) [request setPostValue:task forKey:@"task"];
	if(jsonRequestString != nil) [request setPostValue:jsonRequestString forKey:@"data"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] intValue]] forKey:@"appVersion"];
    if(progressView != nil) [request setDownloadProgressDelegate:progressView];

    if(self.downloadQueue == nil)
    {
        self.downloadQueue = [ASINetworkQueue queue];
        [self.downloadQueue setMaxConcurrentOperationCount:2];
    }
	[self.downloadQueue setShowAccurateProgress:YES];
	[self.downloadQueue setDelegate:self];
	[self.downloadQueue addOperation:request];
	[self.downloadQueue go];
}

- (NSData*)getSyncDataFromServer:(NSString *)requestType withTask:(NSString *)task withData:(NSDictionary *)requestData
{
	NSString *jsonRequestString = nil;
	if(requestData != nil)
	{
		SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
		jsonRequestString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[jsonWriter stringWithObject:requestData], NULL, NULL, kCFStringEncodingUTF8);
		[jsonWriter release];
	}
	
	[appDelegate didStartNetworking];
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/mobile/download.php?apiKey=%@&type=%@&task=%@&data=%@&development=%@&appVersion=%d", appDelegate.apiHost, yongoApiKey, requestType, task, jsonRequestString, appDelegate.productionStage, [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] intValue]]];
    
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setThreadPriority:threadPriority];
	[request setNumberOfTimesToRetryOnTimeout:2];
	[request setShouldAttemptPersistentConnection:YES];
	[request setPersistentConnectionTimeoutSeconds:30];
    [request setTimeOutSeconds:10];
    [request setUsername:@"yongopal"];
    [request setPassword:yongoApiKey];
    [request setValidatesSecureCertificate:NO];
	[request startSynchronous];
    
	NSError *error = [request error];
	NSData *apiResult = nil;
    bool isError = NO;
    int statusCode = [request responseStatusCode];
	
	if(error)
	{
        isError = YES;
        [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
	}
	else
	{
		if(statusCode == 200)
		{
			NSString *contentType = [[request responseHeaders] objectForKey:@"Content-Type"];
			
			// check if response is image
			if([contentType isEqualToString:@"application/json"])
			{
                isError = YES;
                [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
			}
			else if([contentType isEqualToString:@"text/html; charset=UTF-8"])
			{
                isError = YES;                
                [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
			}
			else
			{
				apiResult = [request responseData];
			}
		}
		else
		{
            isError = YES;
			NSDictionary *alertContent = [[NSDictionary alloc] initWithObjectsAndKeys:@"API Error", @"title", [NSString stringWithFormat:@"HTTP status code: %d for request type %@ and task %@", statusCode, requestType, task], @"message", nil];
			[appDelegate performSelectorOnMainThread:@selector(displayAlert:) withObject:alertContent waitUntilDone:YES];
			[alertContent release];
            
            [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
		}
	}

	[appDelegate didStopNetworking];

    // log results
    if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
    {
        NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
        [logData setValue:appDelegate.apiHost forKey:@"server"];
        [logData setValue:requestType forKey:@"requestType"];
        [logData setValue:task forKey:@"task"];
        [logData setValue:jsonRequestString forKey:@"requestData"];
        if([request responseString] != nil && ![[request responseString] isEqualToString:@""])
        {
            [logData setValue:[request responseString] forKey:@"resultData"];
        }
        [logData setValue:[NSNumber numberWithBool:isError] forKey:@"isError"];
        [self performSelectorInBackground:@selector(logApiResults:) withObject:logData];
        [logData release];
    }


    [jsonRequestString release];

	return apiResult;
}

- (void)getAsyncDataFromServer:(NSString *)requestType withTask:(NSString *)task withData:(NSDictionary *)requestData progressDelegate:(UIProgressView*)progressView
{
	NSString *jsonRequestString = nil;
	if(requestData != nil)
	{
		SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
		jsonRequestString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[jsonWriter stringWithObject:requestData], NULL, NULL, kCFStringEncodingUTF8);
		[jsonWriter release];
	}
	
	[appDelegate didStartNetworking];
    
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/mobile/download.php?apiKey=%@&type=%@&task=%@&data=%@&development=%@&appVersion=%d", appDelegate.apiHost, yongoApiKey, requestType, task, jsonRequestString, appDelegate.productionStage, [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] intValue]]];
    
	[jsonRequestString release];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setThreadPriority:threadPriority];
	[request setNumberOfTimesToRetryOnTimeout:2];
	[request setShouldAttemptPersistentConnection:YES];
	[request setPersistentConnectionTimeoutSeconds:30];
    [request setTimeOutSeconds:10];
    [request setUsername:@"yongopal"];
    [request setPassword:yongoApiKey];
    [request setValidatesSecureCertificate:NO];
	[request setDelegate:self];
    if(progressView != nil) [request setDownloadProgressDelegate:progressView];
    
    if(self.downloadQueue == nil)
    {
        self.downloadQueue = [ASINetworkQueue queue];
        [self.downloadQueue setMaxConcurrentOperationCount:2];
    }
	[self.downloadQueue setShowAccurateProgress:YES];
	[self.downloadQueue setDelegate:self];
	[self.downloadQueue addOperation:request];
	[self.downloadQueue go];
}

- (void)uploadImageFile:(NSString*)requestType withTask:(NSString*)task withImageData:(NSData*)data withData:(NSDictionary*)requestData progressDelegate:(UIProgressView*)progressView
{
	if([appDelegate.networkStatus boolValue] == NO)
	{
        [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
		return;
	}
    
	if(data)
	{
		[appDelegate didStartNetworking];
        
		SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
		NSString *jsonMemberData = [jsonWriter stringWithObject:requestData];
		[jsonWriter release];
        
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/mobile/request.php", appDelegate.apiHost]];
		ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request setThreadPriority:threadPriority];
		[request setNumberOfTimesToRetryOnTimeout:2];
        [request setShouldStreamPostDataFromDisk:YES];
		[request setShouldAttemptPersistentConnection:YES];
		[request setPersistentConnectionTimeoutSeconds:30];
        [request setTimeOutSeconds:15];
		[request setPostValue:yongoApiKey forKey:@"apiKey"];
		[request setPostValue:appDelegate.productionStage forKey:@"development"];
		[request setPostValue:requestType forKey:@"type"];
		[request setPostValue:task forKey:@"task"];
		[request setPostValue:jsonMemberData forKey:@"data"];
        [request setPostValue:[NSString stringWithFormat:@"%d", [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] intValue]] forKey:@"appVersion"];
		[request setData:data withFileName:@"image.jpg" andContentType:@"image/jpeg" forKey:@"file"];
        [request setUsername:@"yongopal"];
        [request setPassword:yongoApiKey];
        [request setValidatesSecureCertificate:NO];
		[request setDelegate:self];
        if(progressView != nil) [request setUploadProgressDelegate:progressView];

        if(self.uploadQueue == nil)
        {
            self.uploadQueue = [ASINetworkQueue queue];
            [self.uploadQueue setMaxConcurrentOperationCount:2];
        }
        [self.uploadQueue setShowAccurateProgress:YES];
        [self.uploadQueue setDelegate:self];
		[self.uploadQueue addOperation:request];
		[self.uploadQueue go];
	}
}

- (void)cancelAllAsyncOperations
{
    appDelegate.networkingCount = 0;
    [appDelegate didStopNetworking];
    
    [self.downloadQueue setDelegate:nil];
    [self.uploadQueue setDelegate:nil];

    [self.downloadQueue cancelAllOperations];
    [self.uploadQueue cancelAllOperations];

    [self cancelAllSharedQueues];
    [self cancelAllDownloads];
    [self cancelAllUploads];
}

- (void)cancelAllSharedQueues
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    if(ASIHTTPRequest.sharedQueue.operations.count > 0)
    {
        for (ASIHTTPRequest *req in ASIHTTPRequest.sharedQueue.operations)
        {
            [req setDelegate:nil];
            [req cancel];
        }
    }
    
    [pool drain];
}

- (void)cancelAllDownloads
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    if(self.downloadQueue.operations.count > 0)
    {
        for (ASIHTTPRequest *req in self.downloadQueue.operations)
        {
            [req setDownloadProgressDelegate:nil];
            [req setDelegate:nil];
            [req cancel];
        }
    }
    
    [pool drain];
}

- (void)cancelAllUploads
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    if(self.uploadQueue.operations.count > 0)
    {
        for (ASIHTTPRequest *req in self.uploadQueue.operations)
        {
            [req setUploadProgressDelegate:nil];
            [req setDelegate:nil];
            [req cancel];
        }
    }
    
    [pool drain];
}

- (void)logApiResults:(NSDictionary*)data
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    NSManagedObjectContext *threadContext = [ThreadMOC context];

	NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"ApiLogs" inManagedObjectContext:threadContext];
	[newManagedObject setValue:[data valueForKey:@"server"] forKey:@"server"];
	[newManagedObject setValue:[data valueForKey:@"requestType"] forKey:@"requestType"];
	[newManagedObject setValue:[data valueForKey:@"task"] forKey:@"task"];
	[newManagedObject setValue:[data valueForKey:@"requestData"] forKey:@"requestData"];
	[newManagedObject setValue:[data valueForKey:@"resultData"] forKey:@"resultData"];
	[newManagedObject setValue:[NSDate date] forKey:@"datetime"];
	[newManagedObject setValue:[data valueForKey:@"isError"] forKey:@"isError"];
	[appDelegate saveContext:threadContext];

    [pool drain];
}

#pragma mark - ASIHTTPReqeust delegate
- (void)requestFinished:(ASIHTTPRequest *)request
{
    bool isError = NO;
    id jsonObject = nil;

	// set status code
	int statusCode = [request responseStatusCode];
    NSString *responseString = [request responseString];
    NSDictionary *serverError = nil;

    // if http status is 200
	if(statusCode == 200)
	{
		NSString *contentType = [[request responseHeaders] objectForKey:@"Content-Type"];
		
		// check if response is json
		if([contentType isEqualToString:@"application/json"])
		{
			NSString *json_string = responseString;

			// process request data
			SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
			jsonObject = [jsonParser objectWithString:json_string error:nil];
			[jsonParser release];

            // check if json string is valid
			if(jsonObject != nil)
			{
                // check for server errors
				serverError = [jsonObject objectForKey:@"error"];
				if([serverError count] == 0)
				{
                    // send json response to delegate
                    [delegate didReceiveJson:jsonObject andHeaders:[request responseHeaders]];
				}
                else
                {
                    isError = YES;
                }
			}
            else
            {
                isError = YES;
            }
		}
        // if response is plain text
		else if([contentType isEqualToString:@"text/plain; charset=UTF-8"])
		{
            if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
            {
                NSLog(@"raw result: %@", responseString);
            }
            isError = YES;
		}
        // if reponse is jpeg image binary
		else if([contentType isEqualToString:@"image/jpeg"])
		{
            // send binary data to delegate
			[delegate didReceiveBinary:[request responseData] andHeaders:[request responseHeaders]];
		}
	}
	else
	{
        isError = YES;
	}

    if(isError == YES)
    {
        [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
    }

    if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
    {
        NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];

        if([[request requestMethod] isEqualToString:@"POST"])
        {
            NSString *postString = [[NSString alloc] initWithData:[request postBody] encoding:NSUTF8StringEncoding];
            NSArray *listItems = [postString componentsSeparatedByString:@"&"];
            [postString release];

            for(NSString *var in listItems)
            {
                NSArray *parts = [var componentsSeparatedByString:@"="];
                if([parts count] > 0)
                {
                    NSString *key = [parts objectAtIndex:0];
                    NSString *value = nil;
                    if([parts count] > 1) value = [parts objectAtIndex:1];
                    value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    [requestData setValue:value forKey:key];
                }
            }
        }
        else
        {
            NSString *urlString = [[request url] absoluteString];
            NSArray *urlParts = [urlString componentsSeparatedByString:@"?"];
            if([urlParts count] == 2)
            {
                NSString *uri = [urlParts objectAtIndex:1];
                NSArray *listItems = [uri componentsSeparatedByString:@"&"];
                
                for(NSString *var in listItems)
                {
                    NSArray *parts = [var componentsSeparatedByString:@"="];
                    if([parts count] > 0)
                    {
                        NSString *key = [parts objectAtIndex:0];
                        NSString *value = nil;
                        if([parts count] > 1) value = [parts objectAtIndex:1];
                        value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [requestData setValue:value forKey:key];
                    }
                }
            }
        }

        // log results
        NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
        [logData setValue:appDelegate.apiHost forKey:@"server"];      
        [logData setValue:[requestData valueForKey:@"type"] forKey:@"requestType"];
        [logData setValue:[requestData valueForKey:@"task"] forKey:@"task"];
        [logData setValue:[requestData valueForKey:@"data"] forKey:@"requestData"];
        if([request responseString] != nil && ![[request responseString] isEqualToString:@""])
        {
            [logData setValue:[request responseString] forKey:@"resultData"];
        }
        [logData setValue:[NSNumber numberWithBool:isError] forKey:@"isError"];
        [self performSelectorInBackground:@selector(logApiResults:) withObject:logData];
        [requestData release];
        [logData release];
    }
    
    if([[appDelegate.prefs valueForKey:@"consoleDebugMode"] isEqualToString:@"Y"])
    {
        NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
        
        if([[request requestMethod] isEqualToString:@"POST"])
        {
            NSString *postString = [[NSString alloc] initWithData:[request postBody] encoding:NSUTF8StringEncoding];
            NSArray *listItems = [postString componentsSeparatedByString:@"&"];
            [postString release];
            
            for(NSString *var in listItems)
            {
                NSArray *parts = [var componentsSeparatedByString:@"="];
                if([parts count] > 0)
                {
                    NSString *key = [parts objectAtIndex:0];
                    NSString *value = nil;
                    if([parts count] > 1) value = [parts objectAtIndex:1];
                    value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    [requestData setValue:value forKey:key];
                }
            }
        }
        else
        {
            NSString *urlString = [[request url] absoluteString];
            NSArray *urlParts = [urlString componentsSeparatedByString:@"?"];
            if([urlParts count] == 2)
            {
                NSString *uri = [urlParts objectAtIndex:1];
                NSArray *listItems = [uri componentsSeparatedByString:@"&"];
                
                for(NSString *var in listItems)
                {
                    NSArray *parts = [var componentsSeparatedByString:@"="];
                    if([parts count] > 0)
                    {
                        NSString *key = [parts objectAtIndex:0];
                        NSString *value = nil;
                        if([parts count] > 1) value = [parts objectAtIndex:1];
                        value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [requestData setValue:value forKey:key];
                    }
                }
            }
        }
        [requestData release];
    }

	[appDelegate didStopNetworking];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    if([[request error] code] != 4)
    {
        [appDelegate performSelectorOnMainThread:@selector(hideLoading) withObject:nil waitUntilDone:NO];
    }

    if([[appDelegate.prefs valueForKey:@"debugMode"] isEqualToString:@"Y"])
    {
        bool isError = YES;
        NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
        
        if([[request requestMethod] isEqualToString:@"POST"])
        {
            NSString *postString = [[NSString alloc] initWithData:[request postBody] encoding:NSUTF8StringEncoding];
            NSArray *listItems = [postString componentsSeparatedByString:@"&"];
            [postString release];
            
            for(NSString *var in listItems)
            {
                NSArray *parts = [var componentsSeparatedByString:@"="];
                if([parts count] > 0)
                {
                    NSString *key = [parts objectAtIndex:0];
                    NSString *value = nil;
                    if([parts count] > 1) value = [parts objectAtIndex:1];
                    value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    [requestData setValue:value forKey:key];
                }
            }
        }
        else
        {
            NSString *urlString = [[request url] absoluteString];
            NSArray *urlParts = [urlString componentsSeparatedByString:@"?"];
            if([urlParts count] == 2)
            {
                NSString *uri = [urlParts objectAtIndex:1];
                NSArray *listItems = [uri componentsSeparatedByString:@"&"];
                
                for(NSString *var in listItems)
                {
                    NSArray *parts = [var componentsSeparatedByString:@"="];
                    if([parts count] > 0)
                    {
                        NSString *key = [parts objectAtIndex:0];
                        NSString *value = nil;
                        if([parts count] > 1) value = [parts objectAtIndex:1];
                        value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [requestData setValue:value forKey:key];
                    }
                }
            }
        }

        // log results
        NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
        [logData setValue:appDelegate.apiHost forKey:@"server"];
        [logData setValue:[requestData valueForKey:@"type"] forKey:@"requestType"];
        [logData setValue:[requestData valueForKey:@"task"] forKey:@"task"];
        [logData setValue:[requestData valueForKey:@"data"] forKey:@"requestData"];
        [logData setValue:[request responseString] forKey:@"resultData"];
        [logData setValue:[NSNumber numberWithBool:isError] forKey:@"isError"];
        [self performSelectorInBackground:@selector(logApiResults:) withObject:logData];
        [requestData release];
        [logData release];
    }
    
    if([[appDelegate.prefs valueForKey:@"consoleDebugMode"] isEqualToString:@"Y"])
    {
        NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
        
        if([[request requestMethod] isEqualToString:@"POST"])
        {
            NSString *postString = [[NSString alloc] initWithData:[request postBody] encoding:NSUTF8StringEncoding];
            NSArray *listItems = [postString componentsSeparatedByString:@"&"];
            [postString release];
            
            for(NSString *var in listItems)
            {
                NSArray *parts = [var componentsSeparatedByString:@"="];
                if([parts count] > 0)
                {
                    NSString *key = [parts objectAtIndex:0];
                    NSString *value = nil;
                    if([parts count] > 1) value = [parts objectAtIndex:1];
                    value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    [requestData setValue:value forKey:key];
                }
            }
        }
        else
        {
            NSString *urlString = [[request url] absoluteString];
            NSArray *urlParts = [urlString componentsSeparatedByString:@"?"];
            if([urlParts count] == 2)
            {
                NSString *uri = [urlParts objectAtIndex:1];
                NSArray *listItems = [uri componentsSeparatedByString:@"&"];
                
                for(NSString *var in listItems)
                {
                    NSArray *parts = [var componentsSeparatedByString:@"="];
                    if([parts count] > 0)
                    {
                        NSString *key = [parts objectAtIndex:0];
                        NSString *value = nil;
                        if([parts count] > 1) value = [parts objectAtIndex:1];
                        value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [requestData setValue:value forKey:key];
                    }
                }
            }
        }
        [requestData release];
    }
    
    [appDelegate didStopNetworking];
}

@end
