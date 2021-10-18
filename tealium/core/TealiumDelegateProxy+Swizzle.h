//
//  TealiumDelegateProxy+Swizzle.h
//  TealiumCore
//
//  Created by Enrico Zannini on 18/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
#if COCOAPODS
#import <TealiumSwift/TealiumSwift-Swift.h>
#else
#import <TealiumCore/TealiumCore-Swift.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface TealiumDelegateProxy (Swizzle)

@end

NS_ASSUME_NONNULL_END
#endif
