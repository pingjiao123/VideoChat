//
//  RegistViewController.m
//  VideoChat
//
//  Created by 魏唯隆 on 2017/6/28.
//  Copyright © 2017年 魏唯隆. All rights reserved.
//

#import "RegistViewController.h"
#import <Hyphenate/Hyphenate.h>

@interface RegistViewController ()
{
    __weak IBOutlet UITextField *_usernameTF;
    __weak IBOutlet UITextField *_passwordTF;
    __weak IBOutlet UITextField *_repasswordTF;
    __weak IBOutlet UIButton *_registBt;
}
@end

@implementation RegistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _initView];
}

- (void)_initView {
    _registBt.layer.masksToBounds = YES;
    _registBt.layer.cornerRadius = 4;
}

- (IBAction)register:(id)sender {
    [self.view endEditing:YES];
    
    if(_usernameTF.text == nil || _usernameTF.text.length <= 0){
        [self showHint:@"用户名为空"];
        return;
    }
    
    if(_passwordTF.text == nil || _passwordTF.text.length <= 0){
        [self showHint:@"密码为空"];
        return;
    }
    
    if(_repasswordTF.text == nil || ![_repasswordTF.text isEqualToString:_passwordTF.text]){
        [self showHint:@"两次密码不一致"];
        return;
    }
    
    [self showHudInView:self.view hint:@"注册"];
    EMError *error = [[EMClient sharedClient] registerWithUsername:_usernameTF.text password:_passwordTF.text];
    if (error==nil) {
        [self showHint:@"注册成功"];
        
        [[EMClient sharedClient].options setIsAutoLogin:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:KLoginState];
        
        [UIApplication sharedApplication].delegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Video" bundle:nil] instantiateViewControllerWithIdentifier:@"VIdeoChatNavViewController"];
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
