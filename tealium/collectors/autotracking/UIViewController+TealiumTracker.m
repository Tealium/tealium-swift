//
//  UIViewController+TealiumTracker.m
//
//  Copyright (c) 2013 Tealium. All rights reserved.
//

#import "UIViewController+TealiumTracker.h"

@implementation UIViewController (TealiumTracker)

void (*oViewDidAppear)(id, SEL, bool a);

+ (void)load {
    
    Method origMethod = class_getInstanceMethod(self, @selector(viewDidAppear:));
    oViewDidAppear = (void *)method_getImplementation(origMethod);
    
    if(!class_addMethod(self,
                        @selector(viewDidAppear:),
                        (IMP)TealiumViewDidAppear,
                        method_getTypeEncoding(origMethod))) {
        method_setImplementation(origMethod, (IMP)TealiumViewDidAppear);
    }
}

static void TealiumViewDidAppear(UIViewController *self, SEL _cmd, bool a) {
    
    __weak UIViewController *weakSelf = self;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.tealium.autotracking.view" object:weakSelf];
    
    oViewDidAppear(self, _cmd, a);
}

@end
