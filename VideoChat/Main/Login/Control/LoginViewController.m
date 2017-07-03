//
//  LoginViewController.m
//  VideoChat
//
//  Created by 魏唯隆 on 2017/6/28.
//  Copyright © 2017年 魏唯隆. All rights reserved.
//

#import "LoginViewController.h"
#import <Hyphenate/Hyphenate.h>

@interface LoginViewController ()
{
    __weak IBOutlet UITextField *_usernameTF;
    __weak IBOutlet UITextField *_passwordTF;
    __weak IBOutlet UIButton *_loginBt;
    __weak IBOutlet UIButton *_registBt;
}
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _initView];
}

- (void)_initView {
    _loginBt.layer.masksToBounds = YES;
    _loginBt.layer.cornerRadius = 4;
    _registBt.layer.masksToBounds = YES;
    _registBt.layer.cornerRadius = 4;
}

- (IBAction)login:(id)sender {
    [self.view endEditing:YES];
    
    if(_usernameTF.text == nil || _usernameTF.text.length <= 0){
        [self showHint:@"用户名为空"];
        return;
    }
    
    if(_passwordTF.text == nil || _passwordTF.text.length <= 0){
        [self showHint:@"密码为空"];
        return;
    }
    
    [self showHudInView:self.view hint:@"登录"];
    EMError *error = [[EMClient sharedClient] loginWithUsername:_usernameTF.text password:_passwordTF.text];
    if (!error) {
        [self showHint:@"登录成功"];
        
        [[EMClient sharedClient].options setIsAutoLogin:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:KLoginState];
        
        [UIApplication sharedApplication].delegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Video" bundle:nil] instantiateViewControllerWithIdentifier:@"VIdeoChatNavViewController"];

    }else if(error.code == EMErrorUserNotFound){
        [self showHint:@"用户不存在"];
    }
    else if(error.code == EMErrorUserAuthenticationFailed){
        [self showHint:@"密码验证失败"];
    }
    [self hideHud];
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
