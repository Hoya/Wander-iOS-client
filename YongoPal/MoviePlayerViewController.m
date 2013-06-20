//
//  MoviePlayerViewController.m
//  Wander
//
//  Created by Jiho Kang on 10/2/11.
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

#import "MoviePlayerViewController.h"

@implementation MoviePlayerViewController

- (id)initWithPath:(NSString *)moviePath
{
    // Initialize and create movie URL
    if (self = [super init])
    {
        movieURL = [NSURL fileURLWithPath:moviePath];    
        [movieURL retain];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setView:[[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease]];
	[[self view] setBackgroundColor:[UIColor blackColor]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc 
{
    [mp release];
    [movieURL release];
    [super dealloc];
}

- (void)readyPlayer
{
    mp = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];

    // For 3.2 devices and above
    if ([mp respondsToSelector:@selector(loadState)]) 
    {
        // Set movie player layout
        [mp setControlStyle:MPMovieControlStyleFullscreen];
        [mp setFullscreen:YES];
        
        // May help to reduce latency
        [mp prepareToPlay];
        
        // Register that the load state changed (movie is ready)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerLoadStateChanged:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    }  
    else
    {
        // Register to receive a notification when the movie is in memory and ready to play.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePreloadDidFinish:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    }
    
    // Register to receive a notification when the movie has finished playing. 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void) moviePlayerLoadStateChanged:(NSNotification*)notification 
{
	// Unless state is unknown, start playback
	if ([mp loadState] != MPMovieLoadStateUnknown)
    {
        // Remove observer
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];

        // When tapping movie, status bar will appear, it shows up
        // in portrait mode by default. Set orientation to landscape
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];

        // Rotate the view for landscape playback
        [[self view] setBounds:CGRectMake(0, 0, 480, 320)];
		[[self view] setCenter:CGPointMake(160, 240)];
		[[self view] setTransform:CGAffineTransformMakeRotation(M_PI / 2)]; 

		// Set frame of movieplayer
		[[mp view] setFrame:CGRectMake(0, 0, 480, 320)];

        // Add movie player as subview
        [[self view] addSubview:[mp view]];   

		// Play the movie
		[mp play];
	}
}

- (void)moviePreloadDidFinish:(NSNotification*)notification 
{
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];

    // Play the movie
    [mp play];
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification 
{    
 	// Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];

    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	[self dismissModalViewControllerAnimated:YES];	
}

@end
