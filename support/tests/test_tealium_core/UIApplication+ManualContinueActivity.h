//
//  UIApplication+UIApplication_ManualContinueActivity.h
//  TealiumAppDelegateProxyTests-iOS
//
//  Created by Enrico Zannini on 17/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (ManualContinueActivity)
-(void) manualContinueUserActivity:(nonnull NSUserActivity *) activity;
-(void) manualSceneContinueUserActivity:(nonnull NSUserActivity *) activity  API_AVAILABLE(ios(13));
@end

NS_ASSUME_NONNULL_END
