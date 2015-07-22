#import "SSParseLogger.h"
#import "ParseLog.h"

static NSString *kLoggerSeverity = @"kLoggerSeverity";
static NSString *kLoggerSeverityRefreshDate = @"kLoggerSeverityRefreshDate";

@interface SSParseLogger ()
@property (nonatomic, strong) NSDictionary *severityDict;
@end

@implementation SSParseLogger

+ (instancetype)sharedInstance {
    static SSParseLogger *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SSParseLogger alloc] init];
        _sharedInstance.severityDict = @{
                @"Error" : @1,
                @"Warning" : @2,
                @"Info" : @4,
                @"Debug" : @8,
                @"Verbose" : @16,
        };
        [Parse setApplicationId:kParseAppId
                      clientKey:kParseClientKey];
    });
    return _sharedInstance;
}

- (void)logMessage:(DDLogMessage *)logMessage {
    [self getSeverityValueFromCofig:^(NSString *severity) {
        if (logMessage.flag <= [self flagForSeverity:severity]) {
            ParseLog *log = [ParseLog object];
            log.context = logMessage.message;
            log.date = [NSDate date];
            log.function = logMessage.function;
            log.lineNumber = @(logMessage.line);
            log.deviceName = [UIDevice currentDevice].name;
            log.osVersion = [UIDevice currentDevice].systemVersion;
            log.appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
            log.severity = [self severityForFlag:logMessage.flag];

            if ([PFUser currentUser]) {
                log.user = [PFUser currentUser];
                log.username = [PFUser currentUser].username;
            }

            [log saveEventually];
        }
    }];
#pragma clang diagnostic pop
}

- (NSString *)severityForFlag:(NSInteger)flag {
    return [self.severityDict allKeysForObject:@(flag)].firstObject ?: @"Unknown";
}

- (DDLogFlag)flagForSeverity:(NSString *)severity {
    return (enum DDLogFlag) [self.severityDict[severity] integerValue] ?: DDLogFlagVerbose;
}

- (BOOL)shouldGetConfig {
    NSDate *lastRefreshDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLoggerSeverityRefreshDate];
    if (lastRefreshDate) {
        if ([lastRefreshDate dateByAddingTimeInterval:60 * 60 * 24] > [NSDate date]) {
            return YES;
        }
    } else {
        return YES;
    }

    return NO;
}

- (void)getSeverityValueFromCofig:(void (^)(NSString *severity))block {
    if ([self shouldGetConfig]) {
        [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *config, NSError *error) {
            if (!error) {
                NSString *severityValue = config[@"LoggerSeverity"];
                [[NSUserDefaults standardUserDefaults] setObject:severityValue forKey:kLoggerSeverity];
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLoggerSeverityRefreshDate];
                [[NSUserDefaults standardUserDefaults] synchronize];
                if (block) {
                    block(severityValue);
                }
            } else {
                if (block) {
                    block(nil);
                }
            }
        }];
    } else {
        if (block) {
            block([[NSUserDefaults standardUserDefaults] valueForKey:kLoggerSeverity]);
        }
    }
}

@end
