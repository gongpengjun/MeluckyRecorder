//
//  GPJTableViewController.m
//  MeluckyRecorder
//
//  Created by Gong Pengjun on 14-2-1.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import "GPJTableViewController.h"
#import "Constants.h"
#import "GPJUser.h"

@interface GPJTableViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) UIBarButtonItem *loginBtnItem;
@property (nonatomic, strong) UIBarButtonItem *logoutBtnItem;
@end

@implementation GPJTableViewController

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
        self.title = [NSString stringWithFormat:@"操作员: %@ (%@)", [[GPJUser sharedUser] username], [[GPJUser sharedUser] userid]];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = self.loginBtnItem;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"UITableViewCell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//    cell.textLabel.text = @"新建违章记录";
//    return cell;
//}

#pragma mark - Table view delegate UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - bar item actions

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
