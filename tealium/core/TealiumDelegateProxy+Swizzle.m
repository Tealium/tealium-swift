//
//  TealiumDelegateProxy+Swizzle.m
//  TealiumCore
//
//  Created by Enrico Zannini on 18/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#import "TealiumDelegateProxy+Swizzle.h"
#if TARGET_OS_IOS

@implementation TealiumDelegateProxy (Swizzle)

+ (void)load {
    [self setup];
}

@end
#endif
