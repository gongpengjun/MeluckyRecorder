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
            record.typeid = [dict valueForKey:@"typeid"];
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
    //NSLog(@"uuid: %@ path: %@",uuid,path);
    
    if(!record.imageName)
        record.imageName = @"photo1.jpg";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary* dict = @{
                               @"uuid"       : record.uuid,
                               @"employeeid" : record.employeeid,
                               @"typeid"     : record.typeid,
                               @"place"      : record.place,
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
    NSString* typeid = record.typeid;
    NSString* place = record.place;
    UIImage * image = record.image;
    NSString* operid = [[GPJUser sharedUser] userid];
    
    NSString* deviceid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    //AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //NSLog(@"%s,%d manager.responseSerializer.acceptableContentTypes:%@",__FUNCTION__,__LINE__,manager.responseSerializer.acceptableContentTypes);
    
    NSString *url = @"http://api.gongpengjun.com:90/violations/record.php";
    NSDictionary *parameters = @{@"employeeid": employeeid, @"typeid" : typeid, @"place" : place, @"operid" : operid, @"mobile" : @(1), @"DeviceID": deviceid};
    
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
