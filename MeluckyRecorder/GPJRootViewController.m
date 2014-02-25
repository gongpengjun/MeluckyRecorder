//
//  GPJRootViewController.m
//  MeluckyRecorder
//
//  Created by Gong Pengjun on 14-2-1.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import "GPJRootViewController.h"
#import "Constants.h"
#import "GPJUser.h"
#import "GPJRecordManager.h"
#import "MBProgressHUD.h"
#import "GPJRecord.h"

@interface GPJRootViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) UIBarButtonItem *loginBtnItem;
@property (nonatomic, strong) UIBarButtonItem *logoutBtnItem;
@end

@implementation GPJRootViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.loginBtnItem = self.navigationItem.rightBarButtonItem;
    self.logoutBtnItem = self.navigationItem.leftBarButtonItem;
    self.navigationItem.leftBarButtonItem = self.navigationItem.leftBarButtonItem = nil;
    self.automaticallyAdjustsScrollViewInsets = NO;
    CGFloat topEdge = CGRectGetHeight(self.navigationController.navigationBar.frame);
    self.tableView.contentInset = UIEdgeInsetsMake(topEdge, 0, 0, 0);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if([[GPJUser sharedUser] isLoggedIn])
    {
        self.navigationItem.rightBarButtonItem = self.logoutBtnItem;
        self.title = [NSString stringWithFormat:@"操作员: %@", [[GPJUser sharedUser] username]];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = self.loginBtnItem;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    if([[GPJRecordManager sharedRecordManager] countOfSavedRecords] > 0)
        return 2;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

#pragma mark - Table view delegate UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,indexPath);
    if(indexPath.section == 1 && indexPath.row == 0) {
        [self batchUploadAction];
    }
}


#pragma mark - bar item actions

- (void)batchUploadAction
{
    NSLog(@"%s,%d",__FUNCTION__,__LINE__);
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.dimBackground = YES;
    
    GPJRecordManager* manager = [GPJRecordManager sharedRecordManager];
    
    NSArray* recordsArray = [[GPJRecordManager sharedRecordManager] savedRecords];
    NSUInteger total = [recordsArray count];
    __block NSUInteger succeedCount = 0;
    __block NSUInteger failureCount = 0;
    __block NSUInteger invalidCount = 0;
    
    void (^endBlock)() = ^{
        NSString* message = nil;
        if(succeedCount == total) {
            message = [NSString stringWithFormat:@"上传完成，全部%d个记录上传成功",total];
        } else if (failureCount == total) {
            message = [NSString stringWithFormat:@"上传完成，全部%d个记录都上传失败，请检查您的无线网络。",total];
        } else if (invalidCount == total) {
            message = [NSString stringWithFormat:@"上传完成，全部%d个记录都是无效的",total];
        } else {
            message = [NSString stringWithFormat:@"上传完成，%d个成功，%d个失败，%d个无效。",succeedCount,failureCount,invalidCount];
        }
        hud.completionBlock = ^() {
            [self.tableView reloadData];
        };
        hud.labelText = message;
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:YES afterDelay:1];
    };
    
    for(NSUInteger i = 0; i < total; i++) {
        GPJRecord *record = recordsArray[i];
        if(![record isValidForUpload]) {
            [manager deleteRecordFromDisk:record];
            invalidCount++;
            if(i >= total - 1) {
                endBlock();
            }
            continue;
        }
        [manager uploadRecord:record
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          //NSLog(@"%s,%d JSON: %@",__FUNCTION__,__LINE__,responseObject);
                          hud.mode = MBProgressHUDModeText;
                          hud.margin = 10.f;
                          if([responseObject objectForKey:@"error"]) {
                              invalidCount++;
                          } else {
                              succeedCount++;
                          }
                          [manager deleteRecordFromDisk:record];
                          if(i >= total - 1) {
                              endBlock();
                          }
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          //NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,error);
                          failureCount++;
                          if(i >= total - 1) {
                              endBlock();
                          }
                      }];
    }
}

- (IBAction)logoutAction:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提醒" message:@"确定要注销吗？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    if(buttonIndex == alertView.cancelButtonIndex)
        return;
    [[NSNotificationCenter defaultCenter] postNotificationName:LOGOUT_NOTIFICATION object:self];
}

@end
