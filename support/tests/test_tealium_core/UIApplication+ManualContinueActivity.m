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

-(void) manualSceneWillConnectWithOptions:(UISceneConnectionOptions *)options {
    UIScene * scene = [self connectedScenes].allObjects.firstObject;
    id<UISceneDelegate> delegate = scene.delegate;
    
    [delegate scene:(UIScene*)[NSObject new] willConnectToSession:(UISceneSession*)[NSObject new] options:options];
}

@end

#define SuppressPerformSelectorLeakWarning(Stuff) \
    do { \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
        Stuff; \
        _Pragma("clang diagnostic pop") \
    } while (0)

@implementation MockOpenUrlContext {
    NSURL * _url;
}
    
-(MockOpenUrlContext *)initWithUrl: (nonnull NSURL *) url {
    SEL selector = NSSelectorFromString(@"init");
    if ([super respondsToSelector:selector]) {
        SuppressPerformSelectorLeakWarning(
        self = [super performSelector:selector];
                                           );
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


@implementation MockConnectionOptions {
    NSURL * _url;
    BOOL _isActivity;
}
    
-(MockConnectionOptions *)initWithUrl: (nonnull NSURL *) url isActivity: (BOOL) isActivity {
    SEL selector = NSSelectorFromString(@"init");
    if ([super respondsToSelector:selector]) {
        SuppressPerformSelectorLeakWarning(
        self = [super performSelector:selector];
                                           );
        if (self) {
            _url = url;
            _isActivity = isActivity;
        }
    }
    return self;
}

-(NSSet<NSUserActivity *> *)userActivities {
    if (_isActivity) {
        NSUserActivity * activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = _url;
        return [[NSSet alloc] initWithObjects:activity, nil];
    } else {
        return [super userActivities];
    }
}

-(NSSet<UIOpenURLContext *> *)URLContexts {
    if (!_isActivity) {
        MockOpenUrlContext * context = [[MockOpenUrlContext alloc] initWithUrl:_url];
        return [[NSSet alloc] initWithObjects:context, nil];
    } else {
        return [super URLContexts];
    }
}

@end
