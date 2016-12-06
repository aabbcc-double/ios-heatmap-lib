//
//  ViewController.m
//  ios-heatmap-lib
//
//  Created by Shakhzod Ikromov on 12/6/16.
//  Copyright © 2016 Shakhzod Ikromov. All rights reserved.
//

#import "ViewController.h"
#import "UIView+GRMHeatmap.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIView *scrollContentView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ViewController

- (void)viewDidLoad {
        [super viewDidLoad];

        self.scrollView.contentSize = self.scrollContentView.frame.size;
        [self.scrollView addSubview:self.scrollContentView];
        self.scrollView.grmSceneName = @"scrollView";
}


- (void)didReceiveMemoryWarning {
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}

- (IBAction)onButton1Click:(id)sender {
}
- (IBAction)onButton2Click:(id)sender {
}
- (IBAction)onButton3Click:(id)sender {
}
- (IBAction)onButton4Click:(id)sender {
}
- (IBAction)onButton5Click:(id)sender {
}
- (IBAction)onButton6Click:(id)sender {
}
- (IBAction)onSegmentChanged:(id)sender {
}
- (IBAction)onTriggered:(id)sender {
}
- (IBAction)onChanged:(id)sender {
}
- (IBAction)onSwitchChanged:(id)sender {
}

@end
