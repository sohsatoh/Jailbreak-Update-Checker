#import <Foundation/Foundation.h>
#import "JBUCommandOutputViewController.h"

@interface JBUManager : NSObject <NSURLSessionDelegate, NSURLSessionDownloadDelegate>
+ (instancetype)sharedInstance;
- (void)checkUpdate;
@end