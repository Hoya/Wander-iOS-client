//
//  PingServer.m
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

#import "PingServer.h"

static NSString * DisplayAddressForAddress(NSData * address)
// Returns a dotted decimal string for the specified address (a (struct sockaddr) 
// within the address NSData).
{
    int         err;
    NSString *  result;
    char        hostStr[NI_MAXHOST];
    
    result = nil;
    
    if (address != nil)
	{
        err = getnameinfo([address bytes], (socklen_t) [address length], hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
        if (err == 0)
		{
            result = [NSString stringWithCString:hostStr encoding:NSASCIIStringEncoding];
            assert(result != nil);
        }
    }
	
    return result;
}

@implementation PingServer
@synthesize _pinger;
@synthesize delegate;
@synthesize _sendTimer;
@synthesize time;
@synthesize _hostName;
@synthesize _done;
@synthesize count;
@synthesize limit;
@synthesize pingTime;

- (id)init
{
    self = [super init];
    if(self)
	{
		time = [[NSMutableDictionary alloc] init];
		count = 0;
		if(limit == 0)
		{
			limit = 3;
		}
	}
    return self;
}

- (void)dealloc
{
	count = 0;
	limit = 0;
	[_pinger release];
	[_sendTimer release];
	[time release];
	[_hostName release];

	[super dealloc];
}

- (void)pingWithHostName:(NSString *)hostName
// The Objective-C 'main' for this program.  It creates a SimplePing object 
// and runs the runloop sending pings and printing the results.
{
	_hostName = hostName;

	_pinger = [[SimplePing alloc] initWithHostName:_hostName address:nil];
	[_pinger setDelegate:self];
	[_pinger start];
}

#pragma mark - simple ping delegate
- (void)sendPing
// Called to send a ping, both directly (as soon as the SimplePing object starts up)
// and via a timer (to continue sending pings periodically).
{
	if(count < limit)
	{
		[self._pinger sendPingWithData:nil];
	}
	else
	{
		[self._sendTimer invalidate];
		self._sendTimer = nil;

		float averageTime = pingTime / count;
		//[delegate pingLatency:averageTime forHost:_hostName];
		[delegate pingServer:self doneWithLatency:averageTime forHost:_hostName];
	}
}

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
// A SimplePing delegate callback method.  We respond to the startup by sending a 
// ping immediately and starting a timer to continue sending them every second.
{
	// Send the first ping straight away.
	[self sendPing];
	
	// And start a timer to send the subsequent pings.
	self._sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
// A SimplePing delegate callback method.  We shut down our timer and the 
// SimplePing object itself, which causes the runloop code to exit.
{
	NSLog(@"failed: %@", error);
	
	[self._sendTimer invalidate];
	self._sendTimer = nil;
	
	// No need to call -stop.  The pinger will stop itself in this case.
	// We do however want to nil out pinger so that the runloop stops.
	
	self._pinger = nil;
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the send.
{
	unsigned int seqNum = (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) [packet bytes])->sequenceNumber);
	[time setObject:[NSDate date] forKey:[NSString stringWithFormat:@"%d", (int)seqNum]];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error
// A SimplePing delegate callback method.  We just log the failure.
{
	NSLog(@"#%u send failed: %@", (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) [packet bytes])->sequenceNumber), error);
	if(count > limit)
	{
		[self._sendTimer invalidate];
	}

	count++;
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the reception of a ping response.
{
	//NSString *ip = DisplayAddressForAddress(pinger.hostAddress);
	unsigned int seqNum = (unsigned int) OSSwapBigToHostInt16([SimplePing icmpInPacket:packet]->sequenceNumber);

	NSDate *sentTime = [time objectForKey:[NSString stringWithFormat:@"%d", (int)seqNum]];	
	NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:sentTime];
	if(seqNum != 0)	pingTime += diff;
	//NSLog(@"%d %@(%@) time: %f", (int)seqNum, _hostName, ip, diff);
	count++;
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the receive.
{
	const ICMPHeader *  icmpPtr;
    icmpPtr = [SimplePing icmpInPacket:packet];
    if (icmpPtr != NULL)
	{
		//NSLog(@"#%u unexpected ICMP type=%u, code=%u, identifier=%u", (unsigned int) OSSwapBigToHostInt16(icmpPtr->sequenceNumber), (unsigned int) icmpPtr->type, (unsigned int) icmpPtr->code, (unsigned int) OSSwapBigToHostInt16(icmpPtr->identifier) );
    }
	else
	{
		NSLog(@"unexpected packet size=%zu", (size_t) [packet length]);
    }
}

@end
