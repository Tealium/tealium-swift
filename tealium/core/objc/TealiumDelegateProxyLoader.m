//
//  TealiumDelegateProxyLoader.m
//  TealiumCore
//
//  Created by Enrico Zannini on 18/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#import "TealiumDelegateProxyLoader.h"
#if TARGET_OS_IOS

#if COCOAPODS
#if defined __has_include && __has_include(<TealiumSwift-Swift.h>)
#import <TealiumSwift-Swift.h>
#else
#import <TealiumSwift/TealiumSwift-Swift.h>
#endif
#else
#ifdef SWIFT_PACKAGE
@import TealiumCore;
#else
#import <TealiumCore/TealiumCore-Swift.h>
#endif
#endif

@implementation TealiumDelegateProxyLoader

+(void)load {
    [TealiumDelegateProxy setup];
}

@end
#endif
