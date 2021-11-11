//
//  TealiumDelegateProxy+Swizzle.m
//  TealiumCore
//
//  Created by Enrico Zannini on 18/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#import "TealiumDelegateProxy+Swizzle.h"
#if TARGET_OS_IOS

#if COCOAPODS
#import <TealiumSwift/TealiumSwift-Swift.h>
#else
#ifdef SWIFT_PACKAGE
@import TealiumCore;
#else
#import <TealiumCore/TealiumCore-Swift.h>
#endif
#endif

@implementation TealiumDelegateProxy (Swizzle)

+ (void)load {
    [self setup];
}

@end
#endif
