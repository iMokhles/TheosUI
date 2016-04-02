//
//  TheosProject.h
//  TheosUI
//
//  Created by iMokhles on 01/04/16.
//  Copyright © 2016 iMokhles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BETaskHelper.h"

#ifndef DEFINE_SHARED_INSTANCE_GCD_USING_BLOCK
#define DEFINE_SHARED_INSTANCE_GCD_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject;
#endif

#define TUIlog(format, ...) NSLog(@"[TheosUI] %@", [NSString stringWithFormat:format, ## __VA_ARGS__])
#define IS_OS_LOWER_THAN_7    ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)

@interface TheosProject : NSObject <BETaskHelperDelegate> {
    BETaskHelper *taskHelper;
}

@property NSString *templateNM;
@property NSString *projectName;
@property NSString *projectID;
@property NSString *projectAuthor;
@property NSString *projectBundleID;
@property NSString *projectProcessToKill;
@property (nonatomic, strong) NSDictionary *projectInfo;
+ (instancetype)sharedInstance;
- (NSArray *)getTemplates;
- (void)createNewProject;
- (NSString *)projectsFolder;
- (NSString *)projectFolderFromName:(NSString *)projectName;
@end
