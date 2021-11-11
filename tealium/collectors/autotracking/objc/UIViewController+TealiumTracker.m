//
//  UIViewController+TealiumTracker.m
//
//  Copyright (c) 2013 Tealium. All rights reserved.
//

#import "UIViewController+TealiumTracker.h"

#if TARGET_OS_IOS
#if COCOAPODS
#import <TealiumSwift/TealiumSwift-Swift.h>
#else
#ifdef SWIFT_PACKAGE
@import TealiumAutotracking;
#else
#import <TealiumAutotracking/TealiumAutotracking-Swift.h>
#endif
#endif

@implementation UIViewController (TealiumTracker)

+ (void)load {
    [self setUp];
}

@end
#endif
