//
//  GPJLoginViewController.m
//  MeluckyRecorder
//
//  Created by Gong Pengjun on 14-2-1.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import "GPJLoginViewController.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "GPJUser.h"

@interface GPJLoginViewController () <UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITextField *txtUsername;
@property (nonatomic, strong) IBOutlet UITextField *txtPassword;
@property (nonatomic, strong) IBOutlet UIButton *btnLogin;
@end

@implementation GPJLoginViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.txtUsername becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if([textField isEqual:self.txtUsername])
    {
        // Next
        [self.txtPassword becomeFirstResponder];
    }
    else if([textField isEqual:self.txtPassword])
    {
        // Go
        [self loginAction:textField];
    }
    return YES;
}

- (IBAction)loginAction:(id)sender
{
    //NSLog(@"%s,%d",__FUNCTION__,__LINE__);
    
    NSString* username = self.txtUsername.text;
    NSString* password = self.txtPassword.text;
    
    if(username.length == 0 || password.length == 0)
    {
        [self showAlertWithTitle:@"错误" message:@"用户名和密码都不能为空."];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.dimBackground = YES;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = @"http://api.gongpengjun.com:90/violations/login.php";
    NSDictionary *parameters = @{@"username": username, @"password" : password};
    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"JSON: %@", responseObject);
              if([responseObject objectForKey:@"error"]) {
                  [hud hide:NO];
                  [self showAlertWithTitle:@"ERROR" message:responseObject[@"error"][@"prompt"]];
              } else {
                  NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,responseObject[@"message"]);
                  [hud hide:NO];
                  [[GPJUser sharedUser] didLoggedInWithUserInfo:responseObject[@"user"]];
                  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
              [hud hide:NO];
              [self showAlertWithTitle:@"ERROR" message:[error localizedDescription]];
          }];
}

- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}

@end
