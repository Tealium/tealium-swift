//
//  UIViewController+TealiumTracker.h
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#if COCOAPODS
#import "TealiumAutotracking-Swift-Manual.h"
#else
#import <TealiumAutotracking/TealiumAutotracking-Swift.h>
#endif
#import "UIViewController+TealiumTracker.h"

@implementation UIViewController (TealiumTracker)

+ (void)load {

    [self setUp];
}

@end
