//
//  GPJRecordManager.h
//  MeluckyRecorder
//
//  Created by 巩 鹏军 on 14-2-20.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPJRecord.h"
#import "AFNetworking.h"

@interface GPJRecordManager : NSObject

+ (GPJRecordManager*)sharedRecordManager;

- (NSString*)folderPathOfRecordUUID:(NSString*)recordUUID;
- (NSString*)folderPathOfRecordUUID:(NSString*)recordUUID createIfNotExist:(BOOL)create;

- (void)saveRecord:(GPJRecord*)record
           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)uploadRecord:(GPJRecord*)record
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
@end
