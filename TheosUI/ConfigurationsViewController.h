//
//  ConfigurationsViewController.h
//  TheosUI
//
//  Created by iMokhles on 02/04/16.
//  Copyright © 2016 iMokhles. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ConfigurationsViewControllerDelegateBlock)(NSDictionary *projectInfo);

@interface ConfigurationsViewController : UIViewController
@property (nonatomic, strong) NSString *templateName;
@property (copy, nonatomic, nullable) ConfigurationsViewControllerDelegateBlock projectInfoBlock;
@end
