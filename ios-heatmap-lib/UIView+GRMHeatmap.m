//
//  UIView+GRMHeatmap.m
//  ios-heatmap-lib
//
//  Created by Shakhzod Ikromov on 12/6/16.
//  Copyright © 2016 Shakhzod Ikromov. All rights reserved.
//

#import "UIView+GRMHeatmap.h"
#import <objc/runtime.h>



@implementation UIView (GRMHeatmap)

- (NSString *)grmNearestSceneName {
        UIView *view = [self grmNearestSceneView];
        
        NSString *name;
        if (!!view)
                name = view.grmSceneName;
        if (!name)
                name = @"default";
        return name;
}

- (UIView *)grmNearestSceneViewImpl:(UIView *)view {
        if (!!view.grmSceneName) return view;
        
        if (!!view.superview) return [self grmNearestSceneViewImpl:view.superview];
        
        return view;
}

- (UIView *)grmNearestSceneView {
        return [self grmNearestSceneViewImpl:self];
}

- (void)setGrmSceneName:(NSString *)grmSceneName {
        objc_setAssociatedObject(self, @selector(grmSceneName), grmSceneName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)grmSceneName {
        return objc_getAssociatedObject(self, @selector(grmSceneName));
}

@end
