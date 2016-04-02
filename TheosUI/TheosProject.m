//
//  TheosProject.m
//  TheosUI
//
//  Created by iMokhles on 01/04/16.
//  Copyright © 2016 iMokhles. All rights reserved.
//

#import "TheosProject.h"
#import "MBProgressHUD.h"

@interface TheosProject () {
    MBProgressHUD *hud;
}

@end

@implementation TheosProject

+ (instancetype)sharedInstance {
    
    DEFINE_SHARED_INSTANCE_GCD_USING_BLOCK(^{
        return [[TheosProject alloc] init];
    })
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    
    return self;
}
- (void)ensurePathAt:(NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ( [fm fileExistsAtPath:path] == false ) {
        [fm createDirectoryAtPath:path
      withIntermediateDirectories:YES
                       attributes:nil
                            error:NULL];
    }
}

- (NSString *)projectsFolder {
    
    NSArray *searchPaths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex: 0];
    NSString *pathProjs = [documentPath stringByAppendingPathComponent:@"projs"];
    [self ensurePathAt:pathProjs];
    return pathProjs;
}

- (NSString *)projectFolderFromName:(NSString *)projectName {
    
    return [[self projectsFolder] stringByAppendingPathComponent:projectName];
}

- (void)setProjectFolderPermissions:(NSString *)folder {
    
    NSString *folderPath = [self projectFolderFromName:folder];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithInt:0777] forKey:NSFilePosixPermissions];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error1;
    [fm setAttributes:dict ofItemAtPath:folderPath error:&error1];
    if (error1) {
        TUIlog(@"ERROR: %@", error1.localizedDescription);
    }
    
}
- (NSArray *)getTemplates {
    
    NSMutableArray *templatesArray = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSArray *templatesFiles = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self theosTemplatesPath] error:&error] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    if (error != nil) {
        TUIlog(@"theos isn't installed");
        return nil;
    } else {
        for (NSString *template in templatesFiles) {
            NSString *templateName = [[[template lastPathComponent] stringByDeletingPathExtension] stringByDeletingPathExtension];
            NSString *stringWithoutIphone_ = [templateName
                                             stringByReplacingOccurrencesOfString:@"iphone_" withString:@""];
            [templatesArray addObject:stringWithoutIphone_];
        }
    }
    
    NSArray *sortedArrayOfString = [[templatesArray copy] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)obj1 compare:(NSString *)obj2 options:NSNumericSearch];
    }];
    return sortedArrayOfString;
}

- (void)saveProjectInfo:(NSDictionary *)projectInfo {
    
    NSMutableDictionary *projectsInfoMTBDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"projectsInfoDicts"];
    NSMutableDictionary *projectsInfoMTBDictNEW = nil;
    NSMutableArray *projInfoArray = [NSMutableArray new];
    
    if (!projectsInfoMTBDict) {
        projectsInfoMTBDict = [[NSMutableDictionary alloc] init];
        [projInfoArray addObject:projectInfo];
        [projectsInfoMTBDict setObject:projInfoArray forKey:[projectInfo objectForKey:@"templateName"]];
        [[NSUserDefaults standardUserDefaults] setObject:projectsInfoMTBDict forKey:@"projectsInfoDicts"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        projectsInfoMTBDictNEW = [[NSMutableDictionary alloc] initWithDictionary:projectsInfoMTBDict];
        NSMutableArray *currentArray = [projectsInfoMTBDict valueForKey:[projectInfo objectForKey:@"templateName"]];
        for (NSString *keys in [projectsInfoMTBDict allKeys]) {
            if ([keys isEqualToString:[projectInfo objectForKey:@"templateName"]]) {
                NSMutableArray *array = [projectsInfoMTBDict valueForKey:keys];
                for (NSDictionary *dict in array) {
                    NSString *curName = dict[@"projectName"];
                    NSString *curPKGName = dict[@"packageID"];
                    if ([curName isEqualToString:projectInfo[@"projectName"]] || [curPKGName isEqualToString:projectInfo[@"packageID"]]) {
                        return;
                    }
                }
            }
            
        }
        [projInfoArray addObjectsFromArray:currentArray];
        [projInfoArray addObject:projectInfo];
        
        
        [projectsInfoMTBDictNEW setObject:projInfoArray forKey:[projectInfo objectForKey:@"templateName"]];
        [[NSUserDefaults standardUserDefaults] setObject:projectsInfoMTBDictNEW forKey:@"projectsInfoDicts"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSString *)theosTemplatesPath {
    return @"/var/theos/templates/iphone/";//[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"theos/templates/iphone/"];
}

- (NSString *)theosNicPath {
    return @"/var/theos/bin/nic.pl";//[[NSBundle mainBundle] pathForResource:@"nic" ofType:@"pl" inDirectory:@"theos/bin"];
}
- (void)createNewProject {
    
    hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Creating";
    
    NSTask *task = [[NSTask alloc] init];   // BETaskHelper will retain it for us
    [task setLaunchPath:@"/usr/bin/perl"];
    [task setArguments:[NSArray arrayWithObjects:[self theosNicPath], nil]];
    [task setCurrentDirectoryPath:[self projectsFolder]];
    taskHelper = [[BETaskHelper alloc] initWithDelegate:self forTask:task];
    // Launch task -- must happen via task helper!
    [taskHelper launchTask];
}


#pragma mark - BETaskHelperDelegate

/*
 * Sent when the wrapped task emits a line of output
 *
 * Note: the task wrapper doesn't retain a copy of the output (it's autoreleased), so the receiver
 *       must retain it explicitly
 */
-(void) task:(NSTask *)task hasOutputAvailable:(NSString *)outputLine {
    
    NSLog(@"%@", outputLine);
    
    // Send Input if requested (will be called twice for verification)
    
    if ([outputLine rangeOfString:@"Choose a Template"].location != NSNotFound) {
        
        [taskHelper sendInput:[NSString stringWithFormat:@"%@\n", _templateNM]];
        
    } else if ([outputLine rangeOfString:@"Project Name"].location != NSNotFound) {
        
        [taskHelper sendInput:[NSString stringWithFormat:@"%@\n", _projectName]];
        
    } else if ([outputLine rangeOfString:@"Package Name"].location != NSNotFound) {
        
        [taskHelper sendInput:[NSString stringWithFormat:@"%@\n", _projectID]];
        
    } else if ([outputLine rangeOfString:@"Maintainer"].location != NSNotFound) {
        
        [taskHelper sendInput:[NSString stringWithFormat:@"%@\n", _projectAuthor]];
        
    } else if ([outputLine rangeOfString:@"Maintainer"].location != NSNotFound) {

        [taskHelper sendInput:[NSString stringWithFormat:@"%@\n", _projectAuthor]];
        
    } else if ([outputLine rangeOfString:@"Bundle filter"].location != NSNotFound) {
        
        [taskHelper sendInput:[NSString stringWithFormat:@"%@\n", _projectBundleID]];
        
    } else if ([outputLine rangeOfString:@"terminate upon"].location != NSNotFound) {
        
        [taskHelper sendInput:[NSString stringWithFormat:@"%@\n", _projectProcessToKill]];
        
    } else if ([outputLine rangeOfString:@"There's already"].location != NSNotFound) {
        
        [taskHelper sendInput:[NSString stringWithFormat:@"\n"]];
        
    }
}

/*
 * Sent when the wrapped task completes
 */
-(void) task:(NSTask *)task hasCompletedWithStatus:(int) status {
    
    NSString *message = (status == 0) ? @"Success!" : @"Failed!";
    if ([message isEqualToString:@"Success!"]) {
        [self saveProjectInfo:_projectInfo];
        hud.labelText = @"Done";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self setProjectFolderPermissions:[_projectInfo objectForKey:@"projectName"]]; // won't work well unless we are root
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TUIUpdateProjectsNotification" object:nil];
            [hud hide:YES];
        });
        
    } else {
        hud.labelText = @"Failed";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [hud hide:YES];
        });
    }
    TUIlog(@"%@", message);
    
}
@end
