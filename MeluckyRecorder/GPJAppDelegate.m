//
//  GPJAppDelegate.m
//  MeluckyRecorder
//
//  Created by Gong Pengjun on 14-2-1.
//  Copyright (c) 2014年 www.GongPengjun.com. All rights reserved.
//

#import "GPJAppDelegate.h"
#import "Constants.h"
#import "GPJLoginViewController.h"
#import "GPJUser.h"
#import "GPJRecordManager.h"

@implementation GPJAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [GPJUser sharedUser];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutHandler:) name:LOGOUT_NOTIFICATION object:nil];
    [self performSelector:@selector(startLogin) withObject:nil afterDelay:0];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Login

- (void)startLogin
{
    [[GPJRecordManager sharedRecordManager] loadViolationTypesDatabase];
    [[GPJRecordManager sharedRecordManager] loadEmployeesDatabase];
    if(![[GPJUser sharedUser] isLoggedIn] ){
        [self showLoginViewAnimated:NO];
    } else {
        [self updateDatabase];
    }
}

- (void)showLoginViewAnimated:(BOOL)animated
{
#if 0
    UINavigationController* navController = (UINavigationController*)self.window.rootViewController;
    [navController.viewControllers[0] performSegueWithIdentifier:@"ShowLoginView" sender:self];
#else
    GPJLoginViewController *loginVC = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"GPJLoginViewController"];
    [self.window.rootViewController presentViewController:loginVC animated:animated completion:nil];
#endif
}

- (void)logoutHandler:(NSNotification *)notification {
    [[GPJUser sharedUser] logout];
    [self showLoginViewAnimated:YES];
}

- (void)updateTypesDatabase {
    GPJRecordManager* manager = [GPJRecordManager sharedRecordManager];
    [manager checkTypesUpdateWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"%s,%d JSON: %@",__FUNCTION__,__LINE__,responseObject);
        if([responseObject objectForKey:@"error"])
            return;
        NSDictionary* newTypesDict = responseObject;
        NSInteger oldVersion = [manager.typesDict[@"version"] integerValue];
        NSInteger newVersion = [newTypesDict[@"version"] integerValue];
        NSLog(@"%s,%d oldVersion: %i, newVersion: %i",__FUNCTION__,__LINE__,oldVersion,newVersion);
        if(oldVersion < newVersion) {
            [manager saveTypes:newTypesDict success:nil failure:nil];
        }
    } failure:nil];
}

- (void)updateEmployeesDatabase {
    GPJRecordManager* manager = [GPJRecordManager sharedRecordManager];
    [manager checkEmployeesUpdateWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"%s,%d JSON: %@",__FUNCTION__,__LINE__,responseObject);
        if([responseObject objectForKey:@"error"])
            return;
        NSDictionary* newEmployeesDict = responseObject;
        NSInteger oldVersion = [manager.employeesDict[@"version"] integerValue];
        NSInteger newVersion = [newEmployeesDict[@"version"] integerValue];
        NSLog(@"%s,%d oldVersion: %i, newVersion: %i",__FUNCTION__,__LINE__,oldVersion,newVersion);
        if(oldVersion < newVersion) {
            [manager saveEmployees:newEmployeesDict success:nil failure:nil];
        }
    } failure:nil];
}

- (void)updateDatabase {
    [self updateTypesDatabase];
    [self updateEmployeesDatabase];
}

@end
