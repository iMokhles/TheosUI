//
//  ViewController.m
//  TheosUI
//
//  Created by iMokhles on 01/04/16.
//  Copyright © 2016 iMokhles. All rights reserved.
//

#import "ViewController.h"
#import "TheosProject.h"
#import "UIActionSheet+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "ConfigurationsViewController.h"
#import "MBProgressHUD.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSMutableDictionary *projectDict;
    NSMutableArray *projectsArray;
    NSMutableDictionary *newProjectsDicts;
    MBProgressHUD *hud;
}
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addBarButton;
@property (strong, nonatomic) IBOutlet UITableView *mainTableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    TUIlog(@"%@", [[TheosProject sharedInstance] getTemplates]);
    self.title = @"Projects";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadProjects) name:@"TUIUpdateProjectsNotification" object:nil];
    [self reloadProjects];
}
- (IBAction)refreshTableTapped:(id)sender {
    hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Refreshing";
    [self reloadProjects];
}

- (void)updateTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0 animations:^{
            [_mainTableView reloadData];
        } completion:^(BOOL finished) {
            //Do something after that...
            hud.labelText = @"Done";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [hud hide:YES];
            });
        }];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadProjects {
    newProjectsDicts = [[NSUserDefaults standardUserDefaults] objectForKey:@"projectsInfoDicts"];
    NSLog(@"%@", newProjectsDicts);
    [self updateTable];
}

- (IBAction)addTheosProject:(id)sender {
    
    TUIlog(@"Projects: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"projectsInfoArray"]);
    projectDict = [NSMutableDictionary new];
    [UIActionSheet showFromBarButtonItem:_addBarButton animated:YES withTitle:@"Templates" cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:[[TheosProject sharedInstance] getTemplates] tapBlock:^(UIActionSheet * _Nonnull actionSheet, NSInteger buttonIndex) {
        
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:@"Cancel"]) {
            TUIlog(@"Cancelled");
        } else {
            [projectDict setObject:buttonTitle forKey:@"templateName"];
            [projectDict setObject:[NSNumber numberWithInteger:buttonIndex+1] forKey:@"templateNM"];
            TUIlog(@"TEMPLATE: %@\nNumber: %i\n\n", buttonTitle, buttonIndex+1);
            ConfigurationsViewController *configVC = [self.storyboard instantiateViewControllerWithIdentifier:@"configVC"];
            [configVC setProjectInfoBlock:^(NSDictionary *projectInfo){
                [projectDict addEntriesFromDictionary:projectInfo];
                [self creatNewProjectFromProjectDict:[projectDict copy]];
            }];
            // configVC.templateName = buttonTitle; ( will add it soon )
            [self presentViewController:configVC animated:YES completion:nil];
        }
    }];
}

- (void)creatNewProjectFromProjectDict:(NSDictionary *)projectInfo {
    TheosProject *theosProject = [TheosProject sharedInstance];
    theosProject.templateNM = [projectInfo objectForKey:@"templateNM"];//@"5";
    theosProject.projectName = [projectInfo objectForKey:@"projectName"];//@"testTweak";
    theosProject.projectID = [projectInfo objectForKey:@"packageID"];//@"com.imokhles.testTweak";
    theosProject.projectAuthor = [projectInfo objectForKey:@"authorName"];//@"iMokhles";
    theosProject.projectBundleID = [projectInfo objectForKey:@"filterID"];//@"com.apple.Springboard";
    theosProject.projectProcessToKill = [projectInfo objectForKey:@"killName"];//@"SpringBoard";
    theosProject.projectInfo = projectInfo;
    TUIlog(@"ProjectInfo: %@", projectInfo);
    [theosProject createNewProject];
}

#pragma mark - TableViewDelegate/TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [newProjectsDicts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *projArray = [newProjectsDicts objectForKey:[[newProjectsDicts allKeys] objectAtIndex:section]];
    
    return [projArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[newProjectsDicts allKeys] objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"projectCell"];
    NSMutableArray *currentArray = [newProjectsDicts valueForKey:[[newProjectsDicts allKeys] objectAtIndex:indexPath.section]];
    NSDictionary *projectCellDict = [currentArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [projectCellDict objectForKey:@"projectName"];
    cell.detailTextLabel.text = [projectCellDict objectForKey:@"authorName"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *projectInfo  = projectsArray[indexPath.row];
    NSString *projectPath = [[TheosProject sharedInstance] projectFolderFromName:[projectInfo objectForKey:@"projectName"]];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSError *error1 = nil;
        if ([[NSFileManager defaultManager] removeItemAtPath:projectPath error:&error1]) {
            NSMutableArray *applyChangesArray = projectsArray;
            
            [applyChangesArray removeObjectAtIndex:indexPath.row];
            
            [[NSUserDefaults standardUserDefaults] setObject:applyChangesArray forKey:@"fileInfoArray"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [projectsArray removeAllObjects];
            [self reloadProjects];
        } else {
            if (error1) {
                TUIlog(@"ERROR: %@", error1.localizedDescription);
            }
        }
        
    }
}

- (IBAction)createProjectTest:(id)sender {
    TheosProject *theosProject = [TheosProject sharedInstance];
    theosProject.templateNM = @"5";
    theosProject.projectName = @"testTweak";
    theosProject.projectID = @"com.imokhles.testTweak";
    theosProject.projectAuthor = @"iMokhles";
    theosProject.projectBundleID = @"com.apple.Springboard";
    theosProject.projectProcessToKill = @"SpringBoard";
    
    [theosProject createNewProject];
}

@end
