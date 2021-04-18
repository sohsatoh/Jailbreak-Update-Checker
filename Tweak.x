

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JBUManager.h"
#import "JBUCommandOutputViewController.h"
#include <spawn.h>
#import <AppSupport/CPDistributedMessagingCenter.h>


@interface SBHomeScreenViewController: UIViewController
-(void)showUpdateAlertForJailbreak: (NSNotification *)notification;
@end

// static size_t (*orig_fwrite)(const void *__restrict, size_t, size_t, FILE *__restrict);
// size_t new_fwrite(const void *__restrict ptr, size_t size, size_t nitems, FILE *__restrict stream) {
//     char *str = (char *)ptr;
//     __block NSString *s = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];

//     // [[logInWindowManager share] addPrintWithMessage:s needReturn:false];
//     NSLog(@"fwrite - %@", s);
//     return orig_fwrite(ptr, size, nitems, stream);
// }

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

    // NSLog(@"text = %@", [JBUManager sharedInstance].commandVC.outputView.text);
    return %orig;
}
%end

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
                                                                 [JBUManager sharedInstance].commandVC = [[JBUCommandOutputViewController alloc] init];
                                                                 [JBUManager sharedInstance].commandVC.modalPresentationStyle = UIModalPresentationFullScreen;
                                                                 [self presentViewController:[JBUManager sharedInstance].commandVC animated:YES completion:^() {
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
