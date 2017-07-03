//
//  SettingViewController.m
//  VideoChat
//
//  Created by 魏唯隆 on 2017/6/28.
//  Copyright © 2017年 魏唯隆. All rights reserved.
//

#import "SettingViewController.h"
#import <Hyphenate/Hyphenate.h>
#import <UIViewController+WLAlert.h>

@interface SettingViewController ()
{
    __weak IBOutlet UIButton *_logoutBt;

}
@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _initView];
}

- (void)_initView {
    _logoutBt.layer.masksToBounds = YES;
    _logoutBt.layer.cornerRadius = 4;
}

- (IBAction)logout:(id)sender {
    [self showMyAlert:@"是否退出" withCancelMsg:@"取消" withCancelBlock:nil withCertainMsg:@"退出" withCertainBlock:^{
        EMError *error = [[EMClient sharedClient] logout:YES];
        if (!error) {
            [self showHint:@"退出成功"];
            
            [UIApplication sharedApplication].delegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Login" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginNavViewController"];
        }        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
