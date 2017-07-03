//
//  VIdeoChatViewController.m
//  VideoChat
//
//  Created by 魏唯隆 on 2017/6/28.
//  Copyright © 2017年 魏唯隆. All rights reserved.
//

#import "VIdeoChatViewController.h"
#import <EaseUI.h>
#import "UserListViewController.h"

//#import "CallViewController.h"
#import "VideoCallViewController.h"

@interface VIdeoChatViewController ()<UITableViewDelegate, UITableViewDataSource, EMCallManagerDelegate, EMCallBuilderDelegate>
{
    NSMutableArray *_userData;
    UITableView *_tableView;
    
    
}
@property (strong, nonatomic) VideoCallViewController *videoCallVC;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSObject *callLock;
@property (strong, nonatomic) EMCallSession *currentSession;
@end

@implementation VIdeoChatViewController

- (void)_initVideoCall {
    
    //注册实时通话回调
    [[EMClient sharedClient].callManager addDelegate:self delegateQueue:nil];
    [[EMClient sharedClient].callManager setBuilderDelegate:self];
    
    EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
    //当对方不在线时，是否给对方发送离线消息和推送，并等待对方回应
    options.isSendPushIfOffline = NO;
    [[EMClient sharedClient].callManager setCallOptions:options];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeCall:) name:KNOTIFICATION_CALL object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoAnswerCall) name:@"videoAnswer" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoReject) name:@"videoReject" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoHangup) name:@"videoHangup" object:nil];
    
}

- (void)videoAnswerCall {
    [self answerCall:_currentSession.callId];
}
- (void)videoReject {
    [self hangupCallWithReason:EMCallEndReasonDecline];
}
- (void)videoHangup {
    [self hangupCallWithReason:EMCallEndReasonHangup];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    _userData = @[].mutableCopy;
    
    [self _initVideoCall];
    
    [self _initView];
    
    [self _loadData];
    
}

- (void)_initView {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TableCell"];
}

- (void)_loadData {
    EMError *error = nil;
    NSArray *userlist = [[EMClient sharedClient].contactManager getContactsFromServerWithError:&error];
    if (!error) {
        [_userData removeAllObjects];
        [_userData addObjectsFromArray:userlist];
    }
}

#pragma mark UITableViewDelegate/UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _userData.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableCell" forIndexPath:indexPath];
    cell.textLabel.text = _userData[indexPath.section];
    cell.imageView.image = [UIImage imageNamed:@"EaseUIResource.bundle/messageVideo"];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self makeCallWithUsername:_userData[indexPath.section] type:EMCallTypeVideo];
    
}

- (IBAction)camear:(id)sender {
    UserListViewController *listViewController = [[UserListViewController alloc] init];
    [self.navigationController pushViewController:listViewController animated:YES];
}

/*
// 用户A拨打用户B，用户B会收到这个回调
- (void)callDidReceive:(EMCallSession *)aSession {
    void (^completionBlock)(EMCallSession *, EMError *) = ^(EMCallSession *aCallSession, EMError *aError){
        if(aError == nil){
            dispatch_async(dispatch_get_main_queue(), ^{
                //创建通话实例是否成功
                _videoCallVC = [[VideoCallViewController alloc] initWithCallSession:aCallSession];
                _videoCallVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
                [self presentViewController:_videoCallVC animated:YES completion:nil];
                
            });
        }
    };
    
    [[EMClient sharedClient].callManager startCall:EMCallTypeVideo remoteName:aSession.callId ext:nil completion:^(EMCallSession *aCallSession, EMError *aError) {
        completionBlock(aCallSession, aError);
    }];
}
 */

#pragma mark - NSNotification
- (void)makeCall:(NSNotification*)notify
{
    if (notify.object) {
        EMCallType type = (EMCallType)[[notify.object objectForKey:@"type"] integerValue];
        [self makeCallWithUsername:[notify.object valueForKey:@"chatter"] type:type];
    }
}
// 拨打通话
- (void)makeCallWithUsername:(NSString *)aUsername
                        type:(EMCallType)aType
{
    if ([aUsername length] == 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    void (^completionBlock)(EMCallSession *, EMError *) = ^(EMCallSession *aCallSession, EMError *aError){
        VIdeoChatViewController *strongSelf = weakSelf;
        if (strongSelf) {
            if (aError || aCallSession == nil) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"call.initFailed", @"Establish call failure") message:aError.errorDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
            
            @synchronized (self.callLock) {
                
                NSLog(@"=====%@", aCallSession.callId);
                NSLog(@"=====%@", aCallSession.localName);
                NSLog(@"是否拨打%d", aCallSession.isCaller);
                
                strongSelf.currentSession = aCallSession;
                _videoCallVC = [[VideoCallViewController alloc] initWithCallSession:strongSelf.currentSession];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_videoCallVC) {
                        [self presentViewController:_videoCallVC animated:NO completion:nil];
                    }
                });
            }
            
            [self _startCallTimer];
        }
        else {
            [[EMClient sharedClient].callManager endCall:aCallSession.callId reason:EMCallEndReasonNoResponse];
        }
    };
    
    [[EMClient sharedClient].callManager startCall:aType remoteName:aUsername ext:@"123" completion:^(EMCallSession *aCallSession, EMError *aError) {
        completionBlock(aCallSession, aError);
    }];
}

#pragma mark 接听通话
- (void)answerCall:(NSString *)aCallId
{
    if (!self.currentSession || ![self.currentSession.callId isEqualToString:aCallId]) {
        return ;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = [[EMClient sharedClient].callManager answerIncomingCall:weakSelf.currentSession.callId];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error.code == EMErrorNetworkUnavailable) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"network.disconnection", @"Network disconnection") delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
                    [alertView show];
                }
                else{
                    [weakSelf hangupCallWithReason:EMCallEndReasonFailed];
                }
            });
        }
    });
}

- (void)_startCallTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:50 target:self selector:@selector(_timeoutBeforeCallAnswered) userInfo:nil repeats:NO];
}

- (void)_timeoutBeforeCallAnswered
{
    [self hangupCallWithReason:EMCallEndReasonNoResponse];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"call.autoHangup", @"No response and Hang up") delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)hangupCallWithReason:(EMCallEndReason)aReason
{
    [self _stopCallTimer];
    
    if (self.currentSession) {
        [[EMClient sharedClient].callManager endCall:self.currentSession.callId reason:aReason];
    }
    [self _clearCurrentCallViewAndData];
}

- (void)_stopCallTimer
{
    if (self.timer == nil) {
        return;
    }
    
    [self.timer invalidate];
    self.timer = nil;
}

- (void)_clearCurrentCallViewAndData
{
    @synchronized (_callLock) {
        self.currentSession = nil;
        
        _videoCallVC.isDismissing = YES;
        [_videoCallVC clearData];
        [_videoCallVC dismissViewControllerAnimated:NO completion:nil];
        _videoCallVC = nil;
    }
}


#pragma mark - EMChatManagerDelegate

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages
{
    for (EMMessage *message in aCmdMessages) {
        EMCmdMessageBody *cmdBody = (EMCmdMessageBody *)message.body;
        NSString *action = cmdBody.action;
        if ([action isEqualToString:@"inviteToJoinConference"]) {
            //            NSString *callId = [message.ext objectForKey:@"callId"];
        } else if ([action isEqualToString:@"__Call_ReqP2P_ConferencePattern"]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"已转为会议模式" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

#pragma mark - EMCallManagerDelegate

- (void)callDidReceive:(EMCallSession *)aSession
{
    if (!aSession || [aSession.callId length] == 0) {
        return ;
    }
    
    if ([EaseSDKHelper shareHelper].isShowingimagePicker) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideImagePicker" object:nil];
    }
    
    if(self.currentSession && self.currentSession.status != EMCallSessionStatusDisconnected){
        [[EMClient sharedClient].callManager endCall:aSession.callId reason:EMCallEndReasonBusy];
        return;
    }
    
    @synchronized (_callLock) {
        [self _startCallTimer];
        
        NSLog(@"%@", aSession.callId);
        NSLog(@"%@", aSession.localName);
        NSLog(@"是否拨打%d", aSession.isCaller);
        
        self.currentSession = aSession;
        _videoCallVC = [[VideoCallViewController alloc] initWithCallSession:self.currentSession];
        _videoCallVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_videoCallVC) {
                [self presentViewController:_videoCallVC animated:NO completion:nil];
            }
        });
    }
}

- (void)callDidConnect:(EMCallSession *)aSession
{
    if ([aSession.callId isEqualToString:self.currentSession.callId]) {
        [_videoCallVC stateToConnected];
    }
}

- (void)callDidAccept:(EMCallSession *)aSession
{
    if ([aSession.callId isEqualToString:self.currentSession.callId]) {
        [self _stopCallTimer];
        [_videoCallVC stateToAnswered];
    }
}

- (void)callDidEnd:(EMCallSession *)aSession
            reason:(EMCallEndReason)aReason
             error:(EMError *)aError
{
    if ([aSession.callId isEqualToString:self.currentSession.callId]) {
        
        [self _stopCallTimer];
        
        @synchronized (_callLock) {
            self.currentSession = nil;
            [self _clearCurrentCallViewAndData];
        }
        
        if (aReason != EMCallEndReasonHangup) {
            NSString *reasonStr = @"end";
            switch (aReason) {
                case EMCallEndReasonNoResponse:
                {
                    reasonStr = NSLocalizedString(@"call.noResponse", @"NO response");
                }
                    break;
                case EMCallEndReasonDecline:
                {
                    reasonStr = NSLocalizedString(@"call.rejected", @"Reject the call");
                }
                    break;
                case EMCallEndReasonBusy:
                {
                    reasonStr = NSLocalizedString(@"call.in", @"In the call...");
                }
                    break;
                case EMCallEndReasonFailed:
                {
                    reasonStr = NSLocalizedString(@"call.connectFailed", @"Connect failed");
                }
                    break;
                case EMCallEndReasonUnsupported:
                {
                    reasonStr = NSLocalizedString(@"call.connectUnsupported", @"Unsupported");
                }
                    break;
                case EMCallEndReasonRemoteOffline:
                {
                    reasonStr = NSLocalizedString(@"call.offline", @"Remote offline");
                }
                    break;
                default:
                    break;
            }
            
            if (aError) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:aError.errorDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
                [alertView show];
            }
            else{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:reasonStr delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
    }
}

- (void)callStateDidChange:(EMCallSession *)aSession
                      type:(EMCallStreamingStatus)aType
{
    if ([aSession.callId isEqualToString:self.currentSession.callId]) {
        [_videoCallVC setStreamType:aType];
    }
}

- (void)callNetworkDidChange:(EMCallSession *)aSession
                      status:(EMCallNetworkStatus)aStatus
{
    if ([aSession.callId isEqualToString:self.currentSession.callId]) {
        [_videoCallVC setNetwork:aStatus];
    }
}

#pragma mark - EMCallBuilderDelegate

- (void)callRemoteOffline:(NSString *)aRemoteName
{
    NSString *text = [[EMClient sharedClient].callManager getCallOptions].offlineMessageText;
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:text];
    NSString *fromStr = [EMClient sharedClient].currentUsername;
    EMMessage *message = [[EMMessage alloc] initWithConversationID:aRemoteName from:fromStr to:aRemoteName body:body ext:@{@"em_apns_ext":@{@"em_push_title":text}}];
    message.chatType = EMChatTypeChat;
    
    [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:nil];
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
