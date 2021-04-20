#import "JBUManager.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <CommonCrypto/CommonHMAC.h>


#define kTaurineUrl @"https://sohsatoh.github.io/jbupdatechecker/taurine.json"

static JBUManager *sharedInstance = nil;

@interface JBUManager ()
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionDownloadTask *task;
@property (nonatomic) NSMutableDictionary *hashDict;
@end

@implementation JBUManager
+ (instancetype)sharedInstance {
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [self new];
        }
    }
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Observe day change notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkUpdate) name:NSCalendarDayChangedNotification object:nil];

        // Run CPDistributedMessagingCenter
        CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"jp.soh.jailbreakupdatechecker.center"];
        [messagingCenter runServerOnCurrentThread];

        // Register Messages
        [messagingCenter registerForMessageName:@"message" target:self selector:@selector(handleMessageNamed:withUserInfo:)];

        // Get SHA256
        self.hashDict = [self getFileHashDict];
    }
    return self;
}

- (void)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo {
    // Process userinfo (simple dictionary) and return a dictionary (or nil)
    if (userinfo) {
        NSLog(@"Got message");
        NSString *message = [userinfo objectForKey:@"message"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.commandVC.outputView.text = [self.commandVC.outputView.text stringByAppendingString:message];
        });
    }
}

- (void)checkUpdate {
    if (!self.session && !self.task) {
        // Configure NSURLSession
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.waitsForConnectivity = YES;
        self.session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                     delegate:self
                                                delegateQueue:nil];

        // Configure request
        NSURL *url = [NSURL URLWithString:kTaurineUrl];
        NSURLRequest *request = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                             timeoutInterval:10];

        self.task = [self.session downloadTaskWithRequest:request];

        [self.task resume];
    }
}

- (NSMutableDictionary *)getFileHashDict {
    NSMutableDictionary *hashDict = [NSMutableDictionary dictionary];

    NSArray *jbFiles = @[@"/taurine/amfidebilitate", @"/taurine/jailbreakd", @"/taurine/pspawn_payload.dylib", @"/usr/lib/pspawn_payload-stg2.dylib"];
    [jbFiles enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL *stop) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSString *sha256hash = [self sha256HashWithFilePath:fileURL];
        if (sha256hash) {
            NSString *fileName = [fileURL lastPathComponent];
            [hashDict setObject:sha256hash forKey:fileName];
        }
    }];

    return hashDict;
}

- (NSString *)sha256HashWithFilePath:(NSURL *)fileLocation {
    NSLog(@"fileLocation = %@", fileLocation);

    NSError *error;
    if ([fileLocation checkResourceIsReachableAndReturnError:&error] == NO) {
        NSLog(@"File is not reachable, err: %@", error);
    }

    NSData *fileData = [NSData dataWithContentsOfURL:fileLocation];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(fileData.bytes, (int)fileData.length, result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x", result[i]];
    }
    return ret;
}

// Delegate Methods

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"finish download");

    NSData *data = [NSData dataWithContentsOfURL:location];
    if (data.length != 0) {
        NSError *err;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if (!err) {
            NSLog(@"jsonResponse: %@", jsonResponse);
            if (![jsonResponse[@"sha256"] isEqualToDictionary:self.hashDict]) {
                NSLog(@"Need to show an alert");
                NSLog(@"res: %@", jsonResponse[@"sha256"]);
                NSLog(@"hash: %@", self.hashDict);

                NSNotification *notification = [NSNotification notificationWithName:@"JBUShowUpdateAlertNotification" object:self userInfo:jsonResponse];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            } else {
                NSLog(@"Jailbreak is the latest version.");

                // If the update was made by the JailbreakUpdateChecker, display an alert.
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                if ([defaults objectForKey:@"isInUpdateSessionByJBU"]) {
                    NSLog(@"Show an alert to ask download IPA file");
                    NSNotification *notification = [NSNotification notificationWithName:@"JBUShowIPAAlertNotification" object:self userInfo:jsonResponse];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
                    [defaults removeObjectForKey:@"isInUpdateSessionByJBU"];
                }
            }
        } else {
            NSLog(@"err = %@", err);
        }
    } else {
        NSLog(@"ERROR: file size is zero");
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.session invalidateAndCancel];

    self.task = nil;
    self.session = nil;
}

@end