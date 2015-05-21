//
//  ViewController.m
//  block的转页使用
//
//  Created by iiiiiiiii on 15/5/18.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import "ViewController.h"
#import "LoginViewController.h"
#import "publicValue.h"

@interface ViewController ()
@property (nonatomic,weak) UIButton *my_btn;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton * b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = CGRectMake(100, 100, 100, 100);
//    b.titleLabel.text = @"first";
    [b setTitle:@"frist" forState:UIControlStateNormal];
    b.backgroundColor = [UIColor greenColor];
    self.view.backgroundColor = [UIColor whiteColor ];
    
    [publicValue shareValue].isLogin = NO;
    
    [b addTarget:self action:@selector(hehe) forControlEvents:UIControlEventTouchDown];
    self.my_btn = b ;
    [self.view addSubview:b];
    
}
- (void)hehe{
    LoginViewController *login = [[LoginViewController alloc] initWithResultBlock:^(BOOL isLogin) {
        if (isLogin)
        {
            NSString * heheda = [[publicValue shareValue].userInof objectForKey:@"account"];
            [self.my_btn setTitle:heheda forState:UIControlStateNormal];
            //[publicValue shareValue].strToken = [[publicValue shareValue].userInof objectForKey:@"token"];
        }
    } Animation:YES];
    [self presentViewController:login animated:YES completion:^{
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
