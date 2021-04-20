

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JBUManager.h"
#import "JBUCommandOutputViewController.h"
#include <spawn.h>
#import <AppSupport/CPDistributedMessagingCenter.h>


@interface SBHomeScreenViewController: UIViewController
-(void)showUpdateAlertForJailbreak: (NSNotification *)notification;
@end

%group Sub
%hookf(size_t, fwrite, const void *__restrict ptr, size_t size, size_t nitems, FILE *__restrict stream) {
    // Hooking fwrite just to get output is a bad way obviously.
    // However, popen does not work (maybe because of Swift?)
    char *str = (char *)ptr;
    __block NSString *s = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    CPDistributedMessagingCenter *messagingCenter;
    messagingCenter = [CPDistributedMessagingCenter centerNamed:@"jp.soh.jailbreakupdatechecker.center"];
    NSDictionary *messageDict = @{ @"message": s };
    [messagingCenter sendMessageName:@"message" userInfo:messageDict];
    NSLog(@"JailbreakUpdateChecker - send message - %@", messageDict);

    return %orig;
}
%end

%group Main
%hook SBHomeScreenViewController
-(void)viewDidLoad {
    %orig;

    NSLog(@"viewDidLoad");

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpdateAlertForJailbreak:) name:@"JBUShowUpdateAlertNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpdateAlertForJailbreak:) name:@"JBUShowIPAAlertNotification" object:nil];

    [[JBUManager sharedInstance] checkUpdate];
}

%new
-(void)showUpdateAlertForJailbreak: (NSNotification *)notification {
    // Show an alert on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Show Alert");

        NSString *jbInfo = [notification userInfo][@"name"];
        NSString *message;

        BOOL isUpdateNotification = [notification.name isEqualToString:@"JBUShowUpdateAlertNotification"];

        void (^alertActionHandler)(UIAlertAction *action);

        if (isUpdateNotification) {
            // Update Notification
            message = [[NSString alloc] initWithFormat:@"%@ is available. Do you wish to update now?", jbInfo];
            alertActionHandler = ^(UIAlertAction *action) {
                NSLog(@"Run update");
                [JBUManager sharedInstance].commandVC = [[JBUCommandOutputViewController alloc] init];
                [JBUManager sharedInstance].commandVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:[JBUManager sharedInstance].commandVC animated:YES completion:^() {
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setBool:YES forKey:@"isInUpdateSessionByJBU"];
                    pid_t pid;
                    posix_spawn(&pid, "/usr/local/bin/runjbupdate", NULL, NULL, NULL, NULL);
                }];
            };
        } else {
            // IPA Notificaiton
            message = [[NSString alloc] initWithFormat:@"Successfully update to %@! Do you wish to download IPA file?\n\nChanges\n%@", jbInfo, [notification userInfo][@"description"]];
            alertActionHandler = ^(UIAlertAction *action) {
                NSURLSession *session = [NSURLSession sharedSession];
                NSURL *url = [NSURL URLWithString:[notification userInfo][@"ipaURL"]];
                NSString *originalFileName = [url lastPathComponent];
                [[session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                    NSLog(@"Successfully downloaded the ipa file / location = %@", location);

                    NSURL *tmpFolderPath = [NSURL fileURLWithPath:NSTemporaryDirectory()];
                    NSURL *newFilePath = [tmpFolderPath URLByAppendingPathComponent:originalFileName];
                    if ([newFilePath checkResourceIsReachableAndReturnError:nil]) {
                        // Remove the old file
                        [[NSFileManager defaultManager] removeItemAtURL:newFilePath error:nil];
                    }

                    NSError *err;
                    [[NSFileManager defaultManager] moveItemAtURL:location toURL:newFilePath error:&err];
                    NSLog(@"original path = %@ / moved to %@", location, newFilePath);
                    if (!err) {
                        // Show sharesheet
                        dispatch_async(dispatch_get_main_queue(), ^{
                                           NSArray *activityItems = @[newFilePath];
                                           UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                                           if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                                               activityViewControntroller.popoverPresentationController.sourceView = self.view;
                                               activityViewControntroller.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/4, 0, 0);
                                           }
                                           [self presentViewController:activityViewControntroller animated:YES completion:nil];
                                       });
                    } else {
                        NSLog(@"error - %@", error);
                    }
                }] resume];
            };
        }

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Jailbreak Update" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *updateAction = [UIAlertAction actionWithTitle:isUpdateNotification ? @"Update" : @"Download"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:alertActionHandler];

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
        NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
        NSUInteger count = args.count;
        if (count != 0) {
            NSString *executablePath = args[0];
            NSString *processName = [executablePath lastPathComponent];
            if ([processName isEqualToString:@"SpringBoard"]) %init(Main);  // SpringBoard
            else %init(Sub);                                                // jbupdate
        }
    }
}
