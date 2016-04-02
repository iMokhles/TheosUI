//
//  BETaskHelper.h
//
//  Created by Philipp on 29/12/2007.
//  Copyright 2007 Incredible Bee Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSTask.h"

@protocol BETaskHelperDelegate <NSObject>

/*
 * Sent when the wrapped task emits a line of output
 *
 * Note: the task wrapper doesn't retain a copy of the output (it's autoreleased), so the receiver
 *       must retain it explicitly
 */
 -(void) task:(NSTask *)task hasOutputAvailable:(NSString *)outputLine;

/*
 * Sent when the wrapped task completes
 */
-(void) task:(NSTask *)task hasCompletedWithStatus:(int) status;

@end


@interface BETaskHelper : NSObject {
	NSTask *task;
	id <BETaskHelperDelegate> delegate;
}

#pragma mark Attributes

-(NSTask *) task;


#pragma mark Initialization methods

/*
 * Returns a DTCTaskWrapper object with the given delegate registered for the given task
 */
-(id) initWithDelegate:(id <BETaskHelperDelegate>)aDelegate forTask:(NSTask *)aTask;


#pragma mark Operations

/*
 * Run the task and forward the output it emits to the delegate
 */
-(void) launchTask;

/*
 * Send data to the running task
 */
- (void)sendInput:(NSString *)inputString;

@end
