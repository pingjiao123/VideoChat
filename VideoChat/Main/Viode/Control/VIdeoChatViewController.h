//
//  VIdeoChatViewController.h
//  VideoChat
//
//  Created by 魏唯隆 on 2017/6/28.
//  Copyright © 2017年 魏唯隆. All rights reserved.
//

#import "BaseViewController.h"

@interface VIdeoChatViewController : BaseViewController

//+ (instancetype)sharedManager;

- (void)answerCall:(NSString *)aCallId;

- (void)makeCallWithUsername:(NSString *)aUsername
                        type:(EMCallType)aType;


- (void)hangupCallWithReason:(EMCallEndReason)aReason;

@end
