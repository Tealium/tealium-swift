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

@implementation MockOpenUrlContext {
    NSURL * _url;
}
    
-(MockOpenUrlContext *)initWithUrl: (nonnull NSURL *) url {
    SEL selector = NSSelectorFromString(@"init");
    if ([super respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        self = [super performSelector:selector];
#pragma clang diagnostic pop
        if (self) {
            _url = url;
        }
    }
    return self;
}

-(NSURL *)URL {
    return _url;
}


@end
