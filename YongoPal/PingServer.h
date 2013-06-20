//
//  PingServer.h
//  YongoPal
//
//  Created by Jiho Kang on 5/23/11.
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

#include <sys/socket.h>
#include <netdb.h>

#import <Foundation/Foundation.h>
// SimplePing
#include "SimplePing.h"

@protocol PingServerDelegate
- (void)pingServer:(id)ping doneWithLatency:(float)latency forHost:(NSString*)host;
@end

@interface PingServer : NSObject <SimplePingDelegate>
{
	SimplePing *_pinger;
	id <PingServerDelegate> delegate;
	NSTimer *_sendTimer;
	NSMutableDictionary *time;
	NSString *_hostName;
	BOOL _done;
	int count;
	int limit;
	float pingTime;
}

@property (nonatomic, retain) SimplePing *_pinger;
@property (nonatomic, assign) id <PingServerDelegate> delegate;
@property (nonatomic, retain) NSTimer *_sendTimer;
@property (nonatomic, retain) NSMutableDictionary *time;
@property (nonatomic, retain) NSString *_hostName;
@property (readwrite) BOOL _done;
@property (readwrite) int count;
@property (readwrite) int limit;
@property (readwrite) float pingTime;

- (void)pingWithHostName:(NSString *)hostName;

@end
