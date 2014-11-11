//
//  LoginPageViewController.m
//  SonosProjectInterface
//
//  Created by Suma Reddy on 11/10/14.
//  Copyright (c) 2014 Flatiron. All rights reserved.
//

#import "LoginPageViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AutoAutoLayout.h"

@interface LoginPageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *logoLabel;

@end

@implementation LoginPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //AutoLayout (working from 4S)
    [self.view removeConstraints:self.view.constraints];
    [AutoAutoLayout reLayoutAllSubviewsFromBase:@"4s" forSubviewsOf:self.view];
    
    self.logoLabel.font = [UIFont fontWithName:@"Helvetica-Oblique" size:16];
    self.navigationController.navigationBarHidden=YES;
    
    
   
    
}

-(void)roundButtonDidTap:(UIButton*)tappedButton {
    NSLog(@"roundButtonDidTap Method Called");
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
