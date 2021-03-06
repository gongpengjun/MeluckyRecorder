//
//  GPJRecordManager.m
//  MeluckyRecorder
//
//  Created by 巩 鹏军 on 14-2-20.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import "GPJRecordManager.h"
#import "GPJUser.h"

@interface GPJRecordManager ()
@property (nonatomic, retain) NSString* basePath;
@end

@implementation GPJRecordManager

+ (GPJRecordManager*)sharedRecordManager
{
    static GPJRecordManager * s_recordManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_recordManager = [[self alloc] init];
    });
    return s_recordManager;
}

- (id)init
{
    self = [super init];
    if(self) {
        self.basePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/records"];
        NSLog(@"%s,%d basePath: %@",__FUNCTION__,__LINE__,self.basePath);
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.basePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.basePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return self;
}

#pragma mark - Violating User Info

- (AFHTTPRequestOperation *)getInfoForUserID:(NSString*)userId
                                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.gongpengjun.com:90/violations/employee.php?employeeid=%@",userId];
    return [[AFHTTPRequestOperationManager manager] GET:urlString
                                             parameters:nil
                                                success:success
                                                failure:failure];
    
}

#pragma mark - Violation Types Database

- (void)loadViolationTypesDatabase
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSString * targetPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/types.json"];
        NSString * sourcePath = [[NSBundle mainBundle] pathForResource:@"types" ofType:@"json"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
            if(![[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:targetPath error:&error]) {
                NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,error);
            }
        }
        
        NSData* data = [NSData dataWithContentsOfFile:targetPath options:NSDataReadingMappedIfSafe error:&error];
        if(!data) {
            NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,error);
        }
        self.typesDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(!self.typesDict) {
            NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,error);
        } else {
            //NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,self.typesDict);
            NSParameterAssert([self.typesDict objectForKey:@"version"]);
            NSParameterAssert([self.typesDict objectForKey:@"types"]);
            NSParameterAssert([self.typesDict[@"types"] count] > 0);
            NSLog(@"%s,%d violation type version: %@ count: %i",__FUNCTION__,__LINE__,self.typesDict[@"version"],[self.typesDict[@"types"] count]);
        }
    });
}

- (NSDictionary*)infoOfViolateTypeNumber:(NSString*)number
{
    NSParameterAssert(number);
    NSParameterAssert(self.typesDict);
    NSParameterAssert([self.typesDict objectForKey:@"types"]);
    
    NSDictionary* info = nil;
    NSArray* typesArray = self.typesDict[@"types"];
    for(NSDictionary *typeInfo in typesArray) {
        NSString* typeNum = [typeInfo objectForKey:@"ViolateTypeNum"];
        if([typeNum isEqualToString:number]) {
            info = typeInfo;
            break;
        }
    }
    
    return info;
}

- (AFHTTPRequestOperation *)checkTypesUpdateWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSString *urlString = @"http://api.gongpengjun.com:90/violations/types.php";
    return [[AFHTTPRequestOperationManager manager] GET:urlString
                                             parameters:nil
                                                success:success
                                                failure:failure];
}

- (void)saveTypes:(NSDictionary*)newTypesDict
          success:(void (^)())success
          failure:(void (^)(NSError *error))failure;
{
    self.typesDict = newTypesDict;
    NSError *error = nil;
    NSString * targetPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/types.json"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:newTypesDict options:NSJSONWritingPrettyPrinted error:&error];
    if(data && [data writeToFile:targetPath atomically:YES]) {
        if(success) success();
    } else {
        error = [NSError errorWithDomain:@"GPJError" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"save types failed" }];
        if(failure) failure(error);
    }
}


#pragma mark - Employee Database


- (void)loadEmployeesDatabase;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSString * targetPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/employees.json"];
        NSString * sourcePath = [[NSBundle mainBundle] pathForResource:@"employees" ofType:@"json"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
            if(![[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:targetPath error:&error]) {
                NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,error);
            }
        }
        
        NSData* data = [NSData dataWithContentsOfFile:targetPath options:NSDataReadingMappedIfSafe error:&error];
        if(!data) {
            NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,error);
        }
        self.employeesDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(!self.employeesDict) {
            NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,error);
        } else {
            //NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,self.typesDict);
            NSParameterAssert([self.employeesDict objectForKey:@"version"]);
            NSParameterAssert([self.employeesDict objectForKey:@"employees"]);
            NSParameterAssert([self.employeesDict[@"employees"] count] > 0);
            NSLog(@"%s,%d employees version: %@ count: %i",__FUNCTION__,__LINE__,self.employeesDict[@"version"],[self.employeesDict[@"employees"] count]);
        }
    });
}

- (NSDictionary*)infoOfEmployeeID:(NSString*)idNumber;
{
    NSParameterAssert(idNumber);
    NSParameterAssert(self.employeesDict);
    NSParameterAssert([self.employeesDict objectForKey:@"employees"]);
    
    NSDictionary* info = nil;
    NSArray* employeesArray = self.employeesDict[@"employees"];
    for(NSDictionary *employeeInfo in employeesArray) {
        NSString* idNum = [employeeInfo objectForKey:@"EmployeeID"];
        if([idNum isEqualToString:idNumber]) {
            info = employeeInfo;
            break;
        }
    }
    
    return info;
}

- (AFHTTPRequestOperation *)checkEmployeesUpdateWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSString *urlString = @"http://api.gongpengjun.com:90/violations/employee.php";
    return [[AFHTTPRequestOperationManager manager] GET:urlString
                                             parameters:nil
                                                success:success
                                                failure:failure];
}

- (void)saveEmployees:(NSDictionary*)newEmployeesDict
              success:(void (^)())success
              failure:(void (^)(NSError *error))failure;
{
    self.employeesDict = newEmployeesDict;
    NSError *error = nil;
    NSString * targetPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/employees.json"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:newEmployeesDict options:NSJSONWritingPrettyPrinted error:&error];
    if(data && [data writeToFile:targetPath atomically:YES]) {
        if(success) success();
    } else {
        error = [NSError errorWithDomain:@"GPJError" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"save employees failed" }];
        if(failure) failure(error);
    }
}

#pragma mark - All-in-one

- (NSArray *)checkUpdateWithTypeSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))typeSuccess
                            typeFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))typeFailure
                        employeeSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))employeeSuccess
                        employeeFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))employeeFailure
                        completionBlock:(void (^)(NSArray *operations))completionBlock
{
    NSMutableArray *opertionsArray = [NSMutableArray array];
    
    NSString *urlString = @"http://api.gongpengjun.com:90/violations/types.php";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:typeSuccess failure:typeFailure];
    [opertionsArray addObject:operation];
    
    urlString = @"http://api.gongpengjun.com:90/violations/employee.php";
    request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:employeeSuccess failure:employeeFailure];
    [opertionsArray addObject:operation];
    
    NSArray *batchOperations = [AFURLConnectionOperation batchOfRequestOperations:opertionsArray
                                                                    progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
                                                                        NSLog(@"%s,%d %i/%i",__FUNCTION__,__LINE__,numberOfFinishedOperations,totalNumberOfOperations);
                                                                    } completionBlock:completionBlock];
    [[NSOperationQueue mainQueue] addOperations:batchOperations waitUntilFinished:NO];
    return batchOperations;
}

- (void)updateDatabase {
    [self checkUpdateWithTypeSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
                        [self handleTypeUpdateResponse:responseObject];
                    }
                         typeFailure:nil
                     employeeSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                         [self handleEmployeeUpdateResponse:responseObject];
                     }
                     employeeFailure:nil completionBlock:^(NSArray *operations) {
                         NSLog(@"%s,%d all done",__FUNCTION__,__LINE__);
                     }];
}

- (void)handleTypeUpdateResponse:(id)responseObject
{
    //NSLog(@"%s,%d JSON: %@",__FUNCTION__,__LINE__,responseObject);
    if([responseObject objectForKey:@"error"])
        return;
    GPJRecordManager* manager = [GPJRecordManager sharedRecordManager];
    NSDictionary* newTypesDict = responseObject;
    NSInteger oldVersion = [manager.typesDict[@"version"] integerValue];
    NSInteger newVersion = [newTypesDict[@"version"] integerValue];
    NSLog(@"%s,%d oldVersion: %i, newVersion: %i",__FUNCTION__,__LINE__,oldVersion,newVersion);
    if(oldVersion < newVersion) {
        [manager saveTypes:newTypesDict success:nil failure:nil];
    }
}

- (void)handleEmployeeUpdateResponse:(id)responseObject
{
    //NSLog(@"%s,%d JSON: %@",__FUNCTION__,__LINE__,responseObject);
    if([responseObject objectForKey:@"error"])
        return;
    GPJRecordManager* manager = [GPJRecordManager sharedRecordManager];
    NSDictionary* newEmployeesDict = responseObject;
    NSInteger oldVersion = [manager.employeesDict[@"version"] integerValue];
    NSInteger newVersion = [newEmployeesDict[@"version"] integerValue];
    NSLog(@"%s,%d oldVersion: %i, newVersion: %i",__FUNCTION__,__LINE__,oldVersion,newVersion);
    if(oldVersion < newVersion) {
        [manager saveEmployees:newEmployeesDict success:nil failure:nil];
    }
}

#pragma mark - Record

- (NSString*)infoPath
{
    return [self.basePath stringByAppendingPathComponent:@"Info.plist"];
}

- (NSString*)folderPathOfRecordUUID:(NSString*)recordUUID
{
    NSParameterAssert(recordUUID);
    return [self folderPathOfRecordUUID:recordUUID createIfNotExist:NO];
}

- (NSString*)folderPathOfRecordUUID:(NSString*)uuid createIfNotExist:(BOOL)create
{
    NSParameterAssert(uuid);
    NSError* error = nil;
    NSString* path = [self.basePath stringByAppendingPathComponent:uuid];
    if(create && ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if([[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"%s,%d %@ SUCCEED",__FUNCTION__,__LINE__,uuid);
        } else {
            NSLog(@"%s,%d %@ FAILED: %@",__FUNCTION__,__LINE__,uuid,error);
        }
    }
    return path;
}

- (NSUInteger)countOfSavedRecords
{
    NSUInteger count = 0;
    NSError * error = nil;
    NSArray * subFolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.basePath error:&error];
    count = [subFolders count];
    return count;
}

- (NSArray*)savedRecords
{
    NSUInteger count = 0;
    NSError * error = nil;
    NSArray * subFolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.basePath error:&error];
    count = [subFolders count];
    NSMutableArray * recordsArray = [NSMutableArray arrayWithCapacity:count];
    NSString* folderPath = nil;
    UIImage* photo1 = nil;
    NSData * data = nil;
    NSDictionary* dict = nil;
    GPJRecord * record = nil;
    for (NSString* name in subFolders) {
        folderPath = [self.basePath stringByAppendingPathComponent:name];
        data = [NSData dataWithContentsOfFile:[folderPath stringByAppendingPathComponent:@"record.json"]];
        photo1 = [UIImage imageWithContentsOfFile:[folderPath stringByAppendingPathComponent:@"photo1.jpg"]];
        if(data && photo1) {
            dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            record = [[GPJRecord alloc] init];
            record.uuid = [dict valueForKey:@"uuid"];
            record.employeeid = [dict valueForKey:@"employeeid"];
            record.typenum = [dict valueForKey:@"typenum"];
            record.place = [dict valueForKey:@"place"];
            record.imageName = [dict valueForKey:@"imageName"];
            record.image = photo1;
            [recordsArray addObject:record];
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:folderPath error:nil];
        }
    }
    return recordsArray;
}

- (void)saveRecord:(GPJRecord*)record
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure
{
    NSString* uuid = record.uuid;
    NSString* path = [self folderPathOfRecordUUID:uuid createIfNotExist:NO];
    NSLog(@"uuid: %@ path: %@",uuid,path);
    
    if(!record.imageName)
        record.imageName = @"photo1.jpg";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary* dict = nil;
        if([record.place length] > 0)
            dict = @{
                     @"uuid"       : record.uuid,
                     @"employeeid" : record.employeeid,
                     @"typenum"    : record.typenum,
                     @"place"      : record.place,
                     @"imageName"  : record.imageName
                     };
        else
            dict = @{
                     @"uuid"       : record.uuid,
                     @"employeeid" : record.employeeid,
                     @"typenum"    : record.typenum,
                     @"imageName"  : record.imageName
                     };
        
        UIImage* photo1 = record.image;
        
        NSData* data = nil;
        NSError* error = nil;
        
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            goto END;
        }
        
        // save image to photo1.jpg
        data = UIImageJPEGRepresentation(photo1, 1);
        if(![data writeToFile:[path stringByAppendingPathComponent:record.imageName] atomically:YES]) {
            error = [NSError errorWithDomain:@"GPJError" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"save 'photo1.jpg' failed" }];
            goto END;
        }
        
        // save info to record.json
        data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        if(![data writeToFile:[path stringByAppendingPathComponent:@"record.json"] atomically:YES]) {
            error = [NSError errorWithDomain:@"GPJError" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"save info failed" }];
            failure(error);
            goto END;
        }
        
    END:
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error) {
                failure(error);
            } else {
                success();
            }
        });
    });
}

- (void)deleteRecordFromDisk:(GPJRecord*)record
{
    NSString* uuid = record.uuid;
    NSString* path = [self folderPathOfRecordUUID:uuid createIfNotExist:NO];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError* error = nil;
        if([[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
            NSLog(@"%s,%d %@ SUCCEED",__FUNCTION__,__LINE__,uuid);
        } else {
            NSLog(@"%s,%d %@ FAILED: %@",__FUNCTION__,__LINE__,uuid,error);
        }
    }
}

- (void)uploadRecord:(GPJRecord*)record
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
{
    NSString* employeeid = record.employeeid;
    NSString* typenum = record.typenum;
    NSString* place = record.place;
    UIImage * image = record.image;
    NSString* operid = [[GPJUser sharedUser] userid];
    
    NSString* deviceid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    //AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //NSLog(@"%s,%d manager.responseSerializer.acceptableContentTypes:%@",__FUNCTION__,__LINE__,manager.responseSerializer.acceptableContentTypes);
    
    NSString *url = @"http://api.gongpengjun.com:90/violations/record.php";
    NSDictionary *parameters = nil;
    if([place length] > 0)
        parameters = @{@"employeeid": employeeid, @"typenum" : typenum, @"place" : place, @"operid" : operid, @"mobile" : @(1), @"DeviceID": deviceid};
    else
        parameters = @{@"employeeid": employeeid, @"typenum" : typenum, @"operid" : operid, @"mobile" : @(1), @"DeviceID": deviceid};
    
    //NSLog(@"%s,%d parameters: %@",__FUNCTION__,__LINE__,parameters);
    
    void (^constructBody)(id <AFMultipartFormData> formData) = ^(id <AFMultipartFormData> formData) {
        // the data size of jpg is much smaller than png (1200x1600:1.5MB(jpg)/3.5MB(png))
        NSData* data = UIImageJPEGRepresentation(image,1);
        [formData appendPartWithFileData:data name:@"photo1" fileName:@"Photo1.jpg" mimeType:@"image/jpeg"];
    };

    [[AFHTTPRequestOperationManager manager] POST:url
                                       parameters:parameters
                        constructingBodyWithBlock:constructBody
                                          success:success
                                          failure:failure];
    
}

@end
