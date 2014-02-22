//
//  GPJRecord.m
//  MeluckyRecorder
//
//  Created by 巩 鹏军 on 14-2-20.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import "GPJRecord.h"

@implementation GPJRecord

- (BOOL)isValidForSave
{
    if(self.employeeid.length == 0 ||
       self.typeid.length == 0 ||
       self.place.length == 0 ||
       !self.image ||
       self.uuid.length == 0)
        return NO;
    else
        return YES;
}

- (BOOL)isValidForUpload
{
    if(self.employeeid.length == 0 ||
       self.typeid.length == 0 ||
       self.place.length == 0 ||
       !self.image)
        return NO;
    else
        return YES;
}

@end
