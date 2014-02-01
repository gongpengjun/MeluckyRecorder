//
//  GPJLoginViewController.m
//  MeluckyRecorder
//
//  Created by Gong Pengjun on 14-2-1.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import "GPJLoginViewController.h"

@interface GPJLoginViewController () <UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITextField *txtUsername;
@property (nonatomic, strong) IBOutlet UITextField *txtPassword;
@property (nonatomic, strong) IBOutlet UIButton *btnLogin;
@end

@implementation GPJLoginViewController

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
    NSLog(@"%s,%d",__FUNCTION__,__LINE__);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
