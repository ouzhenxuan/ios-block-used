//
//  LoginViewController.m
//  block的转页使用
//
//  Created by iiiiiiiii on 15/5/19.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import "LoginViewController.h"
#import "publicValue.h"

@interface LoginViewController ()
@property (nonatomic,assign) BOOL isPopAnimation;
@end

@implementation LoginViewController
@synthesize isPopAnimation;
- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton * b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = CGRectMake(100, 100, 100, 100);
    [b setTitle:@"secend" forState:UIControlStateNormal];
    b.backgroundColor = [UIColor greenColor];
    self.view.backgroundColor = [UIColor whiteColor ];
    [b addTarget:self action:@selector(xixi) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:b];
    
}

-(void)xixi{
    
    
    [[publicValue shareValue].userInof setValue:@"ozx" forKey:@"account"];
//    这里是调用一个block，相当于调用了方法，被调用时的block进栈，等待被回调。
//    [self getLoginResult:self.view UserAccount:@"hhehe" PassWord:@"hehe" ResultBlock:^(NSDictionary *dicResult) {
//    
//        if (dicResult) {
            [publicValue shareValue].isLogin = YES;
            getLoginResultBlock([publicValue shareValue].isLogin);
            [self.navigationController popViewControllerAnimated:YES];
            [self dismissViewControllerAnimated:YES completion:^{
            }];
//        }
//    
//    }];
}
////这里的block，相当于一个方法，一调用代码块就会被执行，
//-(void)getLoginResult:(UIView *)viewBack UserAccount:(NSString *)strAccount PassWord:(NSString *)strPwd
//          ResultBlock:(void(^)(NSDictionary *dicResult))block
//{
//    getLoginResultBlockk=nil;
//    getLoginResultBlockk=[block copy];
//    NSDictionary *dicData = @{@"account":@"12345" };//令字典不为空而已,没什么关系的.
//    [[publicValue shareValue].userInof setValue:@"呵呵,改了ozx" forKey:@"account"];
//    getLoginResultBlockk(dicData);
//}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(instancetype)initWithResultBlock:(void(^)(BOOL isLogin))block Animation:(BOOL)isPop
{
    self=[super init];
    if (self)
    {
        getLoginResultBlock=nil;
        getLoginResultBlock=[block copy];
        self.isPopAnimation=isPop;
    }
    return self;
}



@end
