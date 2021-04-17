

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JBUManager.h"
#import "JBUCommandOutputViewController.h"
#include <spawn.h>

@interface SBHomeScreenViewController: UIViewController
-(void)showUpdateAlertForJailbreak: (NSNotification *)notification;
@end

%group Main
%hook SBHomeScreenViewController
-(void)viewDidLoad {
    %orig;

    NSLog(@"viewDidLoad");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpdateAlertForJailbreak:) name:@"JailbreakUpdateNotification" object:nil];

    [NSTimer scheduledTimerWithTimeInterval:60*60*24 repeats:YES block:^(NSTimer *timer) {
        [[JBUManager sharedInstance] checkUpdate];
    }];

    [[JBUManager sharedInstance] checkUpdate];
}

%new
-(void)showUpdateAlertForJailbreak: (NSNotification *)notification {
    // Show an alert on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Show Alert");

        NSString *jbInfo = [notification userInfo][@"name"];
        NSString *message = [[NSString alloc] initWithFormat:@"%@ is available. Do you wish to update now?", jbInfo];

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Jailbreak Update" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *updateAction = [UIAlertAction actionWithTitle:@"Update"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction *action) {
                                                                 NSLog(@"Run update");
                                                                 JBUCommandOutputViewController *commandVC = [[JBUCommandOutputViewController alloc] init];
                                                                 commandVC.modalPresentationStyle = UIModalPresentationFullScreen;
                                                                 [self presentViewController:commandVC animated:YES completion:^() {
                                                                     pid_t pid;
                                                                     posix_spawn(&pid, "/usr/local/bin/runupdatejb", NULL, NULL, NULL, NULL);
                                                                 }];
                                                             }];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {}];

        [alertController addAction:updateAction];
        [alertController addAction:cancelAction];

        [self presentViewController:alertController animated:YES completion:nil];
    });
}
%end
%end

%ctor {
    // Check if using Taurine
    BOOL isTaurine = [[NSFileManager defaultManager] fileExistsAtPath:@"/taurine"];
    if (isTaurine) {
        NSLog(@"init");
        %init(Main);
    }
}
