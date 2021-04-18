#import <Foundation/Foundation.h>
#import "JBUCommandOutputViewController.h"

@interface JBUManager : NSObject <NSURLSessionDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic) JBUCommandOutputViewController *commandVC;
+ (instancetype)sharedInstance;
- (void)checkUpdate;
@end