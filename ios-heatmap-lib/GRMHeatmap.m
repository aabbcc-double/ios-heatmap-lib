//
//  GRMHeatmap.m
//  ios-heatmap-lib
//
//  Created by Shakhzod Ikromov on 12/6/16.
//  Copyright © 2016 Shakhzod Ikromov. All rights reserved.
//

#import "GRMHeatmap.h"
#import "UIView+GRMHeatmap.h"
#import <objc/runtime.h>

#define GRMTouchesArray @"GRMHeatmapTouchesKey"
#define GRMSendThreshold 100
#define GRMSaveThreshold 1000

@interface GRMHeatmap ()

@property NSURL *backendURL;
@property NSString *prefixForIPad;
@property NSMutableArray *buffer;
@property NSMutableSet<NSString *> *renderedScenes;

@end

@interface UIApplication (GRMHeatmap)

+ (void)grmInitialize;

@end

typedef void (^GRMNetworkCompletionBlock)(NSDictionary *response);

@implementation GRMHeatmap

+ (void)requestWithURL:(NSURL *)url withMethod:(NSString *)method withJSON:(id)body withCompletion:(GRMNetworkCompletionBlock)block {
        [self requestWithURL:url withQuery:nil withMethod:method withJSON:body withCompletion:block];
}

+ (void)requestWithURL:(NSURL *)url withQuery:(NSString *)query withMethod:(NSString *)method withJSON:(id)body withCompletion:(GRMNetworkCompletionBlock)block {
        static NSURLSession *session = nil;
        
        if (!session) {
                NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
                configuration.URLCache = nil;
                [NSURLCache setSharedURLCache:[[NSURLCache alloc] initWithMemoryCapacity:0
                                                                            diskCapacity:0
                                                                                diskPath:nil]];
                session = [NSURLSession sessionWithConfiguration:configuration];
        }
        
        if (query) {
                NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
                urlComponents.query = query;
                url = urlComponents.URL;
        }
        
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        urlRequest.HTTPMethod = method;
        if (body != nil)
                urlRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
        
        [[session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSDictionary *defaultResponseJson = @{
                                                      @"meta" : @{
                                                                      @"code" : @(-1)
                                                                      }
                                                      };
                NSDictionary *responseJson = defaultResponseJson;
                
                for (;;) {
                        if (error) break;
                        responseJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                        if (error) {
                                responseJson = defaultResponseJson; // Prevents responseJson becoming nil
                                break;
                        };
                        break;
                }
                
                block(responseJson);
        }] resume];
}

+ (void)setIPadPrefix:(NSString *)prefix {
        [GRMHeatmap sharedInstance].prefixForIPad = prefix;
}

+ (instancetype)sharedInstance {
        static dispatch_once_t onceToken;
        static GRMHeatmap *instance = nil;
        dispatch_once(&onceToken, ^{
                instance = [[GRMHeatmap alloc] init];
                instance.prefixForIPad = @"ipad_";
        });
        return instance;
}

- (void)prepareWithBackendURL:(NSURL *)url {
        self.backendURL = url;
        self.renderedScenes = [NSMutableSet set];
        
        [UIApplication grmInitialize];
        self.buffer = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey:GRMTouchesArray];
        if (!self.buffer) self.buffer = [NSMutableArray array];
}

- (void)prepareWithBackend:(NSString *)url {
        NSURL *u = [NSURL URLWithString:url];
        [self prepareWithBackendURL:u];
}

- (void)addTouch:(CGPoint)p withSceneName:(NSString *)scene {
        BOOL isIPAD = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
        
        NSString *prefix = @"";
        if (!!self.prefixForIPad && isIPAD)
                prefix = self.prefixForIPad;
        
        NSDictionary *t = @{
                            @"timestamp": @([NSDate date].timeIntervalSince1970),
                            @"scene": [prefix stringByAppendingString:scene],
                            @"x": @(p.x),
                            @"y": @(p.y)
                            };
        
        [self.buffer addObject:t];
        
        if (self.buffer.count > GRMSendThreshold)
                [self sendChunkToServer];
}

- (void)sendChunkToServer {
        NSMutableArray *chunk = [NSMutableArray array];
        while (chunk.count < GRMSendThreshold && self.buffer.count > 0) {
                NSDictionary *t = [self.buffer lastObject];
                [chunk addObject:t];
                [self.buffer removeLastObject];
        }
        
        NSURL *url = [self.backendURL URLByAppendingPathComponent:@"/touches"];
        [GRMHeatmap requestWithURL:url withMethod:@"PUT" withJSON:chunk withCompletion:^(NSDictionary *response) {
                NSInteger code = [response[@"meta"][@"code"] integerValue];
                
                if (code == 0) {
                        // Sent successfully
                } else {
                        // Unsuccess, save to later sending
                        NSMutableArray *ar = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey:GRMTouchesArray];
                        if (!ar) ar = [NSMutableArray array];
                        [ar addObjectsFromArray:chunk];
                        [[NSUserDefaults standardUserDefaults] setObject:ar forKey:GRMTouchesArray];
                }
        }];
}

- (void)renderAndSendIfNeeded:(UIView *)view withName:(NSString *)sceneName {
        // Try to render only once
        if ([self.renderedScenes containsObject:sceneName]) return;
        
        
        CGSize size = view.bounds.size;
        CGPoint savedOffset = CGPointZero;
        CGRect savedRect = CGRectZero;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
                UIScrollView *scrollView = (UIScrollView *)view;
                
                // backup
                size = scrollView.contentSize;
                savedOffset = scrollView.contentOffset;
                savedRect = scrollView.frame;
                
                scrollView.contentOffset = CGPointZero;
                scrollView.frame = CGRectMake(savedRect.origin.x - scrollView.contentInset.left,
                                              savedRect.origin.y - scrollView.contentInset.top,
                                              size.width + scrollView.contentInset.right,
                                              size.height + scrollView.contentInset.bottom);
                size = scrollView.frame.size;
        }
        
        
        UIGraphicsBeginImageContextWithOptions(size, view.opaque, 1.0f);
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
        UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if ([view isKindOfClass:[UIScrollView class]]) {
                UIScrollView *scrollView = (UIScrollView *)view;
                
                // restore
                scrollView.frame = savedRect;
                scrollView.contentOffset = savedOffset;
        }
        
        [self.renderedScenes addObject:sceneName];
        
        NSData *data = UIImageJPEGRepresentation(snapshotImage, 0.3);
        if (!data) return;
        
        NSURL __block * url = [[[self.backendURL URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:@"check"] URLByAppendingPathComponent:sceneName];
        [GRMHeatmap requestWithURL:url withMethod:@"GET" withJSON:nil withCompletion:^(NSDictionary *response) {
                NSInteger code = [response[@"meta"][@"code"] integerValue];
                if (code != 0) return;
                
                BOOL needed = [response[@"data"] boolValue];
                if (!needed) return;
                
                url = [[self.backendURL URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:sceneName];
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
                request.HTTPBody = data;
                request.HTTPMethod = @"POST";
                
                [[[NSURLSession sharedSession] dataTaskWithRequest:request] resume];
        }];
}

@end


@implementation UIApplication (GRMHeatmap)

+ (void)grmInitialize {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
                Class class = [self class];
                
                Method originalMethod = class_getInstanceMethod(class, @selector(sendEvent:));
                Method swizzledMethod = class_getInstanceMethod(class, @selector(grm_sendEvent:));
                
                method_exchangeImplementations(originalMethod, swizzledMethod);
                
                
        });
}

- (void)grm_sendEvent:(UIEvent *)event {
        [self grm_sendEvent:event];
        
        UIView *window = self.keyWindow;
        if (!!window) {
                [event.allTouches enumerateObjectsUsingBlock:^(UITouch * _Nonnull touch, BOOL * _Nonnull stop) {
                        CGPoint p = [touch locationInView:window];
                        
                        UIView *targetView = [window hitTest:p withEvent:nil];
                        NSString *scene = @"default";
                        
                        if (!!targetView) {
                                scene = [targetView grmNearestSceneName];
                                targetView = [targetView grmNearestSceneView];
                                p = [touch locationInView:targetView];
                                [[GRMHeatmap sharedInstance] renderAndSendIfNeeded:targetView withName:scene];
                        }
                       
                        [[GRMHeatmap sharedInstance] addTouch:p withSceneName:scene];
                }];
        }
}

@end

#undef GRMTouchesArray
#undef GRMSendThreshold
#undef GRMSaveThreshold
