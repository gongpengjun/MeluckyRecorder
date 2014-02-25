//
//  GPJEditRecordViewController.m
//  MeluckyRecorder
//
//  Created by Gong Pengjun on 14-2-1.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import "GPJEditRecordViewController.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "GPJUser.h"
#import "UIImage+Resize.h"
#import "Constants.h"
#import "GPJRecordManager.h"
#import "GPJRecord.h"

@interface GPJEditRecordViewController () <UITextFieldDelegate,UIActionSheetDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) IBOutlet UITextField *txtEmployeeID;
@property (nonatomic, strong) IBOutlet UITextField *txtViolateTypeNum;
@property (nonatomic, strong) IBOutlet UITextField *txtViolatePlace;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *gottenImage;
@end

@implementation GPJEditRecordViewController

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
    //self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.txtEmployeeID becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if([textField isEqual:self.txtEmployeeID])
    {// Next -> violate type id
        if([self.txtEmployeeID.text length] > 0) {
            GPJRecordManager *manager = [GPJRecordManager sharedRecordManager];
            [manager infoForUserID:self.txtEmployeeID.text
                           success:^(AFHTTPRequestOperation *operation, id responseObject) {
                               NSDictionary* info = responseObject;
                               if([info objectForKey:@"error"]) {
                                   NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,info[@"error"][@"prompt"]);
                               } else {
                                   NSLog(@"%s,%d EmployeeID: %@ UserName: %@ DeptName: %@",__FUNCTION__,__LINE__,info[@"EmployeeID"],info[@"UserName"],info[@"DeptName"]);
                               }
                           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                               NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,error);
                           }];
        }
        [self.txtViolateTypeNum becomeFirstResponder];
    }
    else if([textField isEqual:self.txtViolateTypeNum])
    {// Next -> violate place
        if([self.txtViolateTypeNum.text length] > 0) {
            NSDictionary * info = [[GPJRecordManager sharedRecordManager] infoOfViolateNumber:self.txtViolateTypeNum.text];
            if(info) {
                NSLog(@"%s,%d num: %@ category: %@ name: %@",__FUNCTION__,__LINE__,info[@"ViolateTypeNum"],info[@"ViolateCategoryName"],info[@"ViolateTypeName"]);
            } else {
                NSLog(@"%s,%d violation type doesn't exist.",__FUNCTION__,__LINE__);
            }
        }
        [self.txtViolatePlace becomeFirstResponder];
    }
    else if([textField isEqual:self.txtViolatePlace])
    {// Next -> violate Photo
        [self pickPhotoAction:self.imageView];
    }
    else
    {// Next -> Go - Upload
        [self uploadAction:textField];
    }
    //
    return YES;
}

#pragma mark - Photo

- (IBAction)pickPhotoAction:(UIView*)fromView {
    [self.view endEditing:YES];
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil
                                                    delegate:self
                                           cancelButtonTitle:nil
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"拍摄照片", @"选取照片", nil];
    [as showFromRect:fromView.frame inView:fromView.superview animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
    } else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
        [self takePhoto];
    } else {
        [self choosePhotos];
    }
}

- (void)takePhoto {
    //NSLog(@"%s,%d",__FUNCTION__,__LINE__);
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:@"There is no camera!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)choosePhotos {
    //NSLog(@"%s,%d",__FUNCTION__,__LINE__);
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    if(image) {
        [MBProgressHUD showHUDAddedTo:picker.view animated:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.gottenImage = [self resizedImage:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
                [MBProgressHUD hideHUDForView:picker.view animated:YES];
                [picker dismissViewControllerAnimated:YES completion:nil];
            });
        });
    } else {
        self.gottenImage = nil;
        self.imageView.image = [UIImage imageNamed:@"placeholder"];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

#define kUploadImageMaxSize 800

- (UIImage*)resizedImage:(UIImage*)originalImage {
    if(!originalImage)
        return nil;
    double factor = (double)originalImage.size.width / (double)originalImage.size.height;
    CGFloat width  = 0;
    CGFloat height = 0;
    if (originalImage.size.height > originalImage.size.width) {
        height = kUploadImageMaxSize;
        width  = kUploadImageMaxSize * factor;
    } else {
        width  = kUploadImageMaxSize;
        height = kUploadImageMaxSize / factor;
    }
    
    UIImage* retImage = originalImage;
    if (MAX(originalImage.size.height, originalImage.size.width) > kUploadImageMaxSize) {
        retImage = [originalImage resizedImage:CGSizeMake(width, height) interpolationQuality:kCGInterpolationHigh];
    }
    return retImage;
}

#pragma mark - Actions

- (IBAction)saveAction:(id)sender {
    //NSLog(@"%s,%d",__FUNCTION__,__LINE__);
    if(![[GPJUser sharedUser] isLoggedIn])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:LOGOUT_NOTIFICATION object:self];
        return;
    }
    
    GPJRecord* record = [self constructRecordFromInputFields];
    
    if(![record isValidForSave])
    {
        [self showAlertWithTitle:@"错误" message:@"员工号、违章条款、违章地点、违章照片都不能为空."];
        return;
    }
    
    [self doSaveRecord:record];
}

- (void)uploadAction:(id)sender
{
    if(![[GPJUser sharedUser] isLoggedIn])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:LOGOUT_NOTIFICATION object:self];
        return;
    }
    
    GPJRecord* record = [self constructRecordFromInputFields];
    
    if(![record isValidForUpload])
    {
        [self showAlertWithTitle:@"错误" message:@"员工号、违章条款、违章地点、违章照片都不能为空."];
        return;
    }
    
    [self doUploadRecord:record];
}

#pragma mark - action implementation

- (GPJRecord*)constructRecordFromInputFields
{
    GPJRecord* record = [[GPJRecord alloc] init];
    record.uuid = [[NSUUID UUID] UUIDString];
    record.employeeid = self.txtEmployeeID.text;
    record.typenum = self.txtViolateTypeNum.text;
    record.place = self.txtViolatePlace.text;
    record.image = self.gottenImage;
    return record;
}

- (void)doSaveRecord:(GPJRecord*)record
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.dimBackground = YES;
    GPJRecordManager* manager = [GPJRecordManager sharedRecordManager];
    [manager saveRecord:record
                success:^{
                    //NSLog(@"%s,%d %@ SUCCEED",__FUNCTION__,__LINE__,record.uuid);
                    hud.labelText = @"保存成功";
                    hud.completionBlock = ^() {
                        [self.navigationController popViewControllerAnimated:YES];
                    };
                    hud.mode = MBProgressHUDModeText;
                    hud.margin = 10.f;
                    hud.removeFromSuperViewOnHide = YES;
                    [hud hide:YES afterDelay:1];
                } failure:^(NSError *error) {
                    //NSLog(@"%s,%d %@ FAILED: %@",__FUNCTION__,__LINE__,record.uuid,error);
                    hud.mode = MBProgressHUDModeText;
                    hud.labelText = [error localizedDescription];
                    hud.margin = 10.f;
                    hud.removeFromSuperViewOnHide = YES;
                    [hud hide:YES afterDelay:1];
                }];
}

- (void)doUploadRecord:(GPJRecord*)record
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.dimBackground = YES;
    GPJRecordManager* manager = [GPJRecordManager sharedRecordManager];
    [manager uploadRecord:record
                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                      //NSLog(@"%s,%d JSON: %@",__FUNCTION__,__LINE__,responseObject);
                      // Configure for text only and offset down
                      if([responseObject objectForKey:@"error"]) {
                          hud.completionBlock = nil;
                          [hud hide:NO];
                          [self showAlertWithTitle:@"错误" message:responseObject[@"error"][@"prompt"]];
                      } else {
                          hud.labelText = responseObject[@"message"];
                          hud.completionBlock = ^() {
                              [self.navigationController popViewControllerAnimated:YES];
                          };
                      }
                      hud.mode = MBProgressHUDModeText;
                      hud.margin = 10.f;
                      hud.removeFromSuperViewOnHide = YES;
                      [hud hide:YES afterDelay:1];
                  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                      //NSLog(@"%s,%d %@",__FUNCTION__,__LINE__,error);
                      hud.mode = MBProgressHUDModeText;
                      hud.labelText = [error localizedDescription];
                      hud.margin = 10.f;
                      hud.removeFromSuperViewOnHide = YES;
                      [hud hide:YES afterDelay:1];
                  }];
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return 4;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//    return cell;
//}

#pragma mark - Table view delegate UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            [self.txtEmployeeID becomeFirstResponder];
            break;
        case 1:
            [self.txtViolateTypeNum becomeFirstResponder];
            break;
        case 2:
            [self.txtViolatePlace becomeFirstResponder];
            break;
        case 3:
            [self pickPhotoAction:self.imageView];
            break;
        case 4:
            [self uploadAction:tableView];
            break;
        default:
            break;
    }
}

#pragma mark - Helper

- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}

@end
