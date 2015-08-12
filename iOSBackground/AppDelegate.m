//
//  AppDelegate.m
//  iOSBackground
//
//  Created by Richard Lee on 8/4/15.
//  Copyright (c) 2015 weimed. All rights reserved.
//

#import <Parse/Parse.h>
#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Remote Notification
    [Parse setApplicationId:@"9sDF7utxArxjiVIKl0r1x3ECRVF8GZbi6Ry7FeJv"
                  clientKey:@"gPClfhPbCHAVAENjn80RVyQg5MzU9GNWpwCjyJpY"];
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    // Stop the timer when the application will resign active
    [self.timer invalidate];
    self.timer = nil;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    application.applicationIconBadgeNumber = 0;

    // Take an example to start a timer when application becomes active
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(scheduledTask:) userInfo:nil repeats:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"Background Fetch: Called in the background!");
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

#pragma mark - Silient Notification App Delegate Method

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"Remote Notification userInfo is %@", userInfo);
    
    NSNumber *contentID = userInfo[@"content-id"];
    NSLog(@"Content ID = %@", contentID);
    
    NSString *valueToSave = @"Silent";
    [[NSUserDefaults standardUserDefaults] setObject:valueToSave forKey:@"RemoteNotification"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    completionHandler(UIBackgroundFetchResultNewData);
}

#pragma mark - Background Transfer Service Delegate Method

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    self.backgroundSessionCompletionHandler = completionHandler;

    // add notification
    [self presentNotification];
}

- (void)presentNotification {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = @"Download Complete!";
    localNotification.alertAction = @"Background Transfer Download!";

    //play sound
    localNotification.soundName = UILocalNotificationDefaultSoundName;

    //increase the badge number of application plus 1
    localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;

    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

#pragma mark - Timer Schedule Task
- (void)scheduledTask:(NSTimer *)timer {
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Sydney"]];
    NSLog(@"%@",[formatter stringFromDate:now]);
}

@end
