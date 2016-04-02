//
//  BETaskHelper.m
//
//  Created by Philipp on 29/12/2007.
//  Copyright 2007 Incredible Bee Ltd. All rights reserved.
//

#import "BETaskHelper.h"


// Private methods
@interface BETaskHelper ()

// Intercepts task data, breaks it into lines and forwards each line to the delegate
-(void) taskDataAvailable:(NSNotification *)aNotification;

@end


@implementation BETaskHelper

#pragma mark Attributes

-(NSTask *) task {
	return task;
}


#pragma mark Initialization methods

-(id) initWithDelegate:(id <BETaskHelperDelegate>)aDelegate forTask:(NSTask *)aTask {
	self = [super init];
	
    task = aTask; //[aTask retain];
    delegate = aDelegate; //[aDelegate retain];
	
	return self;
}

-(void) dealloc {
	// Stop receiving notifications (otherwise the line below where we release the task will
	// crash the app since it the notification center sends a message to a no-longer existent
	// object)
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:nil];
	
//	[task release];
//	[delegate release];
//	
//	[super dealloc];
}


#pragma mark Operations

-(void) launchTask {
	// Setup the output handling
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError:[task standardOutput]];
	
	// Task input
	NSPipe *inputPipe = [NSPipe pipe];
    [task setStandardInput:inputPipe];
	
	// Setup unbuffered I/O. This isn't as trivial as it sounds because when
	// we set an environment variable via setEnvironment: then the task no
	// longer inherits our environment, including $PATH. Thus we first load
	// our environment, then add the current task's environment in case the
	// client has made any custom settings. Only then do we set unbuffered
	// I/O.
	//
	// Note: we create an empty dictionary first in case the task's environment
	//       is nil, which NSTask doesn't accept
	NSMutableDictionary *environment = [NSMutableDictionary dictionary];
	[environment addEntriesFromDictionary:[[NSProcessInfo processInfo] environment]];
	[environment addEntriesFromDictionary:[task environment]];
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
	[task setEnvironment:environment];
	
	// Register as observer when the task emits output
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(taskDataAvailable:) 
												 name:NSFileHandleReadCompletionNotification 
											   object:[[task standardOutput] fileHandleForReading]];
	
	// We tell the file handle to go ahead and read in the background asynchronously, and notify
	// us via the callback registered above when we signed up as an observer.  The file handle will
	// send a NSFileHandleReadCompletionNotification when it has data that is available.
	[[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	
	// Launch the task asynchronously
	[task launch];
}

- (void)sendInput:(NSString *)inputString {
	NSPipe *inputPipe = [task standardInput];
    [[inputPipe fileHandleForWriting] writeData:[inputString dataUsingEncoding:NSUTF8StringEncoding]];
}


#pragma mark Private methods

-(void) taskDataAvailable:(NSNotification *)aNotification {
	// Parse the data from the notification object and if any data is found, break into lines
	// and forward each line to the delegate
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]) {
		// Read the raw data into a readable string
		NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

		// Break the text into lines and notify the delegate of each line
		for (NSString *line in [text componentsSeparatedByString:@"\n"]) {
			[delegate task:task hasOutputAvailable:line];
		}
		
		// Wait for more more input
		[[aNotification object] readInBackgroundAndNotify];
	}
	// Terminate if there's no more data left
	else {
		// Terminate the task
		[task terminate];
		[task waitUntilExit];
		
		// Remove ourselves as observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:[[task standardOutput] fileHandleForReading]];
		
		// Inform the delegate we're done
		[delegate task:task hasCompletedWithStatus:[task terminationStatus]];
	}
}

@end
