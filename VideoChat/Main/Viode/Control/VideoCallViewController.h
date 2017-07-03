//
//  VideoCallViewController.h
//  VideoChat
//
//  Created by 魏唯隆 on 2017/6/29.
//  Copyright © 2017年 魏唯隆. All rights reserved.
//

#import "BaseViewController.h"

@interface VideoCallViewController : BaseViewController

@property (strong, nonatomic, readonly) EMCallSession *callSession;

@property (nonatomic) BOOL isDismissing;

- (instancetype)initWithCallSession:(EMCallSession *)aCallSession;

- (void)stateToConnected;

- (void)stateToAnswered;

- (void)setNetwork:(EMCallNetworkStatus)aStatus;

- (void)setStreamType:(EMCallStreamingStatus)aType;

- (void)clearData;

@end
