//
//  GPJCookieFix.h
//  Messages
//
//  Created by 巩 鹏军 on 14-1-3.
//  Copyright (c) 2014年 巩 鹏军. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CookieManager : NSObject

+ (void)saveCookies;
+ (void)loadCookies;
+ (void)deleteCookies;

@end
