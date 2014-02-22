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

- (NSString*)folderPathOfRecordUUID:(NSString*)recordUUID createIfNotExist:(BOOL)create
{
    NSParameterAssert(recordUUID);
    NSString* path = [self.basePath stringByAppendingPathComponent:recordUUID];
    if(create && ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (void)saveRecord:(GPJRecord*)record
           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSString* uuid = record.uuid;
    NSString* path = [self folderPathOfRecordUUID:uuid createIfNotExist:YES];
    NSLog(@"uuid: %@ path: %@",uuid,path);
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
