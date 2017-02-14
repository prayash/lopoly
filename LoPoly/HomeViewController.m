//
//  HomeViewController.m
//  LoPoly
//
//  Created by Prayash Thapa on 2/13/17.
//  Copyright © 2017 Prayash Thapa. All rights reserved.
//

#import "HomeViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor alloc] initWithRed:0.96 green:0.15 blue:0.39 alpha:1.0];
    
    UIBarButtonItem *flipButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Flip"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(flipView:)];
    self.navigationItem.rightBarButtonItem = flipButton;
}

-(IBAction)flipView:(id)sender {
    NSLog(@"flipView.");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
