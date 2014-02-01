//
//  GPJUser.h
//  MeluckyRecorder
//
//  Created by Gong Pengjun on 14-2-1.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPJUser : NSObject

+ (id)sharedUser;

- (BOOL)isLoggedIn;
- (NSString*)userid;
- (NSString*)username;
- (NSString*)password;

- (void)didLoggedInWithUserInfo:(NSDictionary*)userInfo;
- (void)logout;

@end
