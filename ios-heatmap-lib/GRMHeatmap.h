//
//  GRMHeatmap.h
//  ios-heatmap-lib
//
//  Created by Shakhzod Ikromov on 12/6/16.
//  Copyright © 2016 Shakhzod Ikromov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GRMHeatmap : NSObject

+ (instancetype)sharedInstance;
+ (void)setIPadPrefix:(NSString *)prefix; // defaults to "ipad_"

- (void)prepareWithBackendURL:(NSURL *)url;
- (void)prepareWithBackend:(NSString *)url;

@end
