//
//  LoginViewController.h
//  block的转页使用
//
//  Created by iiiiiiiii on 15/5/19.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LoginViewController : UIViewController
{
    ///登录成功后返回的block
    void(^getLoginResultBlock)(BOOL isLogin);
    void(^getLoginResultBlockk)(NSDictionary *dicResult);
    //是否能促发动画
    BOOL isAnimation;
}

-(instancetype)initWithResultBlock:(void(^)(BOOL isLogin))block Animation:(BOOL)isPop;
-(void)getLoginResult:(UIView *)viewBack UserAccount:(NSString *)strAccount PassWord:(NSString *)strPwd
          ResultBlock:(void(^)(NSDictionary *dicResult))block;
@end
