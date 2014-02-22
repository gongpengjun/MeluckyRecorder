//
//  GPJRecord.h
//  MeluckyRecorder
//
//  Created by 巩 鹏军 on 14-2-20.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPJRecord : NSObject
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *employeeid;
@property (nonatomic, retain) NSString *typeid;
@property (nonatomic, retain) NSString *place;
@property (nonatomic, retain) UIImage  *image;
@property (nonatomic, retain) NSString *imageName;

- (BOOL)isValidForSave;
- (BOOL)isValidForUpload;

@end
