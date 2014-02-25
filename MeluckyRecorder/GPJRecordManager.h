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

@property (nonatomic, strong) NSDictionary * typesDict;

+ (GPJRecordManager*)sharedRecordManager;

#pragma mark - Violation Types Database

- (void)loadViolationTypesDatabase;

- (NSDictionary*)infoOfViolateNumber:(NSString*)number;

- (AFHTTPRequestOperation *)getInfoForUserID:(NSString*)userId
                                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

#pragma mark - Record

- (NSUInteger)countOfSavedRecords;

- (NSArray*)savedRecords;

- (void)saveRecord:(GPJRecord*)record
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

- (void)deleteRecordFromDisk:(GPJRecord*)record;

- (void)uploadRecord:(GPJRecord*)record
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
@end
