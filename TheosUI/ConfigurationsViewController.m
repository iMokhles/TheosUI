//
//  ConfigurationsViewController.m
//  TheosUI
//
//  Created by iMokhles on 02/04/16.
//  Copyright © 2016 iMokhles. All rights reserved.
//

#import "ConfigurationsViewController.h"
#import "TheosProject.h"

@interface ConfigurationsViewController () <UITextFieldDelegate> {
    int mainKeyboardHeight;
}
@property (strong, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) IBOutlet UITextField *killField;
@property (strong, nonatomic) IBOutlet UITextField *filterField;
@property (strong, nonatomic) IBOutlet UITextField *authorField;
@property (strong, nonatomic) IBOutlet UITextField *packageIdField;
@property (strong, nonatomic) IBOutlet UITextField *projectNameField;
@property (strong, nonatomic) IBOutlet UIView *centerView;

@end

@implementation ConfigurationsViewController
@synthesize projectInfoBlock;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupNotifications];
    
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (IBAction)doneTapped:(id)sender {
    
    NSMutableDictionary *projectInfoDict = [NSMutableDictionary new];
    [projectInfoDict setObject:_projectNameField.text forKey:@"projectName"];
    [projectInfoDict setObject:_packageIdField.text forKey:@"packageID"];
    [projectInfoDict setObject:_authorField.text forKey:@"authorName"];
    [projectInfoDict setObject:_filterField.text forKey:@"filterID"];
    [projectInfoDict setObject:_killField.text forKey:@"killName"];
    [self dismissViewControllerAnimated:YES completion:^{
        projectInfoBlock([projectInfoDict copy]);
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    if (textField == _projectNameField) {
        [_packageIdField becomeFirstResponder];
    } else if (textField == _packageIdField) {
        [_authorField becomeFirstResponder];
    } else if (textField == _authorField) {
        [self resizeCenterViewWithHeight:mainKeyboardHeight+100 isDone:NO];
        [_filterField becomeFirstResponder];
    } else if (textField == _filterField) {
        [self resizeCenterViewWithHeight:mainKeyboardHeight+200 isDone:NO];
        [_killField becomeFirstResponder];
    } else if (textField == _killField) {
        [self resizeCenterViewWithHeight:0 isDone:YES];
        [textField resignFirstResponder];
    }
    return YES;
}

#pragma mark - Keyboard Notifications

- (void)resizeCenterViewWithHeight:(NSInteger)height isDone:(BOOL)isDone {
    if (!isDone) {
        [UIView animateWithDuration:0.7
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:(void (^)(void)) ^{
                             [_centerView setTransform:CGAffineTransformMakeTranslation(0, -height)];
                         }
                         completion:^(BOOL finished){
                         }];
    } else {
        [UIView animateWithDuration:0.7
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:(void (^)(void)) ^{
                             [_centerView setTransform:CGAffineTransformMakeTranslation(0, 0)];
                         }
                         completion:^(BOOL finished){
                         }];
    }
    
}
- (void)keyboardWillShow:(NSNotification *)notification {
    
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    int height = MIN(keyboardSize.height,keyboardSize.width);
    mainKeyboardHeight = height-110;
    [UIView animateWithDuration:0.7
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:(void (^)(void)) ^{
                         [_centerView setTransform:CGAffineTransformMakeTranslation(0, -mainKeyboardHeight)];
                     }
                     completion:^(BOOL finished){
                     }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [UIView animateWithDuration:0.7
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:(void (^)(void)) ^{
                         [_centerView setTransform:CGAffineTransformMakeTranslation(0, 0)];
                     }
                     completion:^(BOOL finished){
                     }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
