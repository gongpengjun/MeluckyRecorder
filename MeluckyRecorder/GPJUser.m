//
//  GPJUser.m
//  MeluckyRecorder
//
//  Created by Gong Pengjun on 14-2-1.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import "GPJUser.h"
#import "CookieManager.h"

@implementation GPJUser

+ (id)sharedUser
{
    static GPJUser* s_user = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_user = [[self alloc] init];
    });
    return s_user;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [CookieManager loadCookies];        
    }
    return self;
}

- (BOOL)isLoggedIn
{
    BOOL isLoggedIn = [[NSUserDefaults standardUserDefaults] boolForKey:@"userLoggedIn"];
    return isLoggedIn;
}

- (NSString*)userid
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"userid"];
}

- (NSString*)username;
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
}

- (NSString*)password;
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
}

- (void)didLoggedInWithUserInfo:(NSDictionary*)userInfo
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"userLoggedIn"];
    if([userInfo objectForKey:@"userid"])
    {
        NSString* userid = userInfo[@"userid"];
        [[NSUserDefaults standardUserDefaults] setObject:userid forKey:@"userid"];
    }
    if([userInfo objectForKey:@"username"])
    {
        NSString* username = userInfo[@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
    }
    if([userInfo objectForKey:@"password"])
    {
        NSString* password = userInfo[@"password"];
        [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [CookieManager saveCookies];
}

- (void)logout
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"userLoggedIn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [CookieManager deleteCookies];    
}

@end
