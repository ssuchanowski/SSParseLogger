//
//  SSParseLogger.h
//  iDoc24 Answers
//
//  Created by Sebastian Suchanowski on 22/10/14.
//  Copyright (c) 2014 iDoc24. All rights reserved.
//

#import "DDLog.h"

@interface SSParseLogger : DDAbstractLogger <DDLogger>

+ (instancetype)sharedInstance;

@end
