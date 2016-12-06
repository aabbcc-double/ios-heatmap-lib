//
//  UIView+GRMHeatmap.h
//  ios-heatmap-lib
//
//  Created by Shakhzod Ikromov on 12/6/16.
//  Copyright © 2016 Shakhzod Ikromov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (GRMHeatmap)

@property (nullable) NSString *grmSceneName;

- (NSString * _Nonnull)grmNearestSceneName;
- (UIView * _Nullable)grmNearestSceneView;

@end
