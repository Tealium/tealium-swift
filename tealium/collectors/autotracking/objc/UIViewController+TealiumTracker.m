//
//  UIViewController+TealiumTracker.m
//
//  Copyright (c) 2013 Tealium. All rights reserved.
//

#import "UIViewController+TealiumTracker.h"

#if TARGET_OS_IOS || TARGET_OS_TV
#if COCOAPODS
#if defined __has_include && __has_include(<TealiumSwift-Swift.h>)
#import <TealiumSwift-Swift.h>
#else
#import <TealiumSwift/TealiumSwift-Swift.h>
#endif
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
