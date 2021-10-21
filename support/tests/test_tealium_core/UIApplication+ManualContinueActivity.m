//
//  UIApplication+ManualContinueActivity.m
//  TealiumAppDelegateProxyTests-iOS
//
//  Created by Enrico Zannini on 17/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#import "UIApplication+ManualContinueActivity.h"

@implementation UIApplication (ManualContinueActivity)

-(void) manualContinueUserActivity:(nonnull NSUserActivity *) activity {
    [[self delegate] application:self continueUserActivity: activity restorationHandler:^(NSArray<id<UIUserActivityRestoring>> * _Nullable restorableObjects) {
            
    }];
}


-(void) manualSceneContinueUserActivity:(nonnull NSUserActivity *) activity  API_AVAILABLE(ios(13)) {
    UIScene * scene = [self connectedScenes].allObjects.firstObject;
    id<UISceneDelegate> delegate = scene.delegate;
    [delegate scene:scene continueUserActivity:activity];
}

@end
