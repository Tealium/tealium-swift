//
//  UIViewController+TealiumTracker.m
//
//  Copyright (c) 2013 Tealium. All rights reserved.
//

#if TARGET_OS_IPHONE

#if autotracking
#import <TealiumAutotracking/TealiumAutotracking-Swift.h>
#else
#import <TealiumSwift/TealiumSwift-Swift.h>
#endif
#import "UIViewController+TealiumTracker.h"

@implementation UIViewController (TealiumTracker)

+ (void)load {
    [self setUp];
}

@end
#endif
