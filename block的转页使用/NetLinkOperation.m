//
//  NetLinkOperation.m
//  ShoppingData
//
//  Created by ChenMacmini on 14-8-13.
//  Copyright (c) 2014年 ANJUBAO. All rights reserved.
//

#import "NetLinkOperation.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPSessionManager.h"
#import "AFURLSessionManager.h"
#import "APService.h"

#import "ChatViewController.h"
#import "DGPublicValue.h"

@implementation NetLinkOperation

-(instancetype)init
{
    self=[super init];
    if (self)
    {
        if (!sqlOper)
        {
            sqlOper=[[SqliteOperation alloc] init];
        }
        
    }
    return self;
}

+(id)defaultNetLink
{
    static dispatch_once_t once;
    static NetLinkOperation *defaultLink;
    dispatch_once(&once, ^
    {
        defaultLink = [[NetLinkOperation alloc] init];
    });
    return defaultLink;
}

#pragma mark 1.用户登录
/**
 *  用户登录
 *
 *  @param viewBack   提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strAccount 登录账户 手机号或者都要id
 *  @param strPwd     登录密码
 *  @param block      返回登录信息 如果返回值为nil则登录失败，否则登录成功，通过字典获取登录信息
 *                    返回值备注：dyId:都要Id , phone:手机号码,   isMerchantAccount:是否为商户（1:是,2:否）
 */
-(void)getLoginResult:(UIView *)viewBack UserAccount:(NSString *)strAccount PassWord:(NSString *)strPwd
          ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    //account pwd
    getLoginResultBlock=nil;
    getLoginResultBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在登录..";
    }
    __weak typeof(self) weakSelf = self;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.securityPolicy.allowInvalidCertificates = YES;
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    [parameters setObject:strAccount?strAccount:@"" forKey:@"account"];
    [parameters setObject:[PublicValue md5:strPwd] forKey:@"pwd"];
    manager.securityPolicy.allowInvalidCertificates = YES;
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_ACCOUNT_LOGIN_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode = MBProgressHUDModeText;
         [HUD hide:YES afterDelay:0];
         //返回结果状态值
         id result = GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult = [result intValue];
         //等于0 请求成功
         if (intResult == 0)
         {
//             [HUD hide:YES];
             [PublicValue shareValue].isLocationSuccessNotification=YES;
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             
             //登录成功赋值用户信息
             if (dicData)
             {
                 //把字典传给单例
                 [[PublicValue shareValue].dicUserInfo removeAllObjects];
                 [[PublicValue shareValue].dicUserInfo setDictionary:dicData];
                 
                 [DGPublicValue shareValue].UserID = GET_OBJECT_OR_NULL([dicData objectForKey:@"account"]);
                 [DGPublicValue shareValue].strToken =GET_OBJECT_OR_NULL([dicData objectForKey:@"token"]);
#pragma mark 在这里对单例对象中的isLogin赋值
                 if (![PublicValue shareValue].isLogin)
                 {
                     [PublicValue shareValue].isLogin = YES;
                 }
             }
             
             ///登录成功加载注册门铃来电模块
//             [PublicValue setDoorBell];
             if (getLoginResultBlock)
             {
                 getLoginResultBlock(dicData);
                 [weakSelf setTagsAndalias:dicData];
             }
             
             ///登录成功之后获取小区列表
             RecommendNetLink *reNet=[[RecommendNetLink alloc] init];
             [reNet findCommunityListForServer:NO ResultBlock:nil];
             ///获取是否拥有店铺
             [[SMNetworkRequest defaultNetLink] getIsMerchantForServer:nil];
             
             
             //登录后获取红点状态

//             NSString *redPointStatue = [PublicValue getDataFromLocal:[NSString stringWithFormat:@"PropertyMessageIsRead_%@",[PublicValue shareValue].dicUserInfo[@"account"]]];
//             
//             if(redPointStatue == nil){
//                 
//                 redPointStatue = @"YES";
//                 
//                 [PublicValue saveDataToLocal:@"YES" KEY:[NSString stringWithFormat:@"PropertyMessageIsRead_%@",[PublicValue shareValue].dicUserInfo[@"account"]]];
//             }
//             
//             [[NSNotificationCenter defaultCenter]postNotificationName:@"PropertyMessageNofication" object:nil userInfo:@{@"isRead":@([redPointStatue isEqualToString:@"YES"]?YES:NO)}];
             
             BOOL isRead= [ChatViewController propeytyMessageIsRead];
             
             [[NSNotificationCenter defaultCenter]postNotificationName:@"PropertyMessageNofication" object:nil userInfo:@{@"isRead":@(isRead)}];
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"登录失败！";
             }
//             HUD.labelText=strMessage;
             [SVProgressHUD showErrorWithStatus:strMessage duration:2.0];
             [HUD hide:YES afterDelay:1];
             if (getLoginResultBlock)
             {
                 getLoginResultBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"登录出错！";
         [HUD hide:YES afterDelay:1];
         if (getLoginResultBlock)
         {
             getLoginResultBlock(nil);
         }
     }
     ];

}

#pragma mark 2.用户注册
/**
 *  用户注册
 *
 *  @param viewBack     提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strPhone     注册的手机号
 *  @param strPwd       注册填写的密码
 *  @param strVerifCode 验证码
 *  @param intType      注册类型 1为手机注册 2为用户名注册 3为邮箱注册
 *  @param block        返回注册信息 如果返回值为nil则注册失败，返回值备注：dyId:都要Id[服务端生成] , 
 *                      phone:手机号码,   isMerchantAccount:是否为商户,注册时默认值2（1:是,2:否）
 */
-(void)getRegister:(UIView *)viewBack UserPhone:(NSString *)strPhone PassWord:(NSString *)strPwd
         VerifCode:(NSString *)strVerifCode RegisterType:(int)intType ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    //例:phone=15920545759&pwd=123456&VerifCode=6532
    // type=1 手机号 type=2 用户名 type=3 邮箱
    getRegisterBlock=nil;
    getRegisterBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在注册..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    //    [parameters setObject:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:strPhone?strPhone:@"" forKey:@"account"];
    [parameters setObject:[PublicValue md5:strPwd] forKey:@"pwd"];
    
    //验证码不为空和手机注册模式才添加
    if (strVerifCode&&intType==1)
    {
        [parameters setObject:strVerifCode?strVerifCode:@"" forKey:@"verifCode"];
    }
    [parameters setObject:[NSString stringWithFormat:@"%d",intType] forKey:@"type"];
    manager.securityPolicy.allowInvalidCertificates = YES;

//    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
//    manager.responseSerializer = [AFJSONResponseSerializer serializer];
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_ACCOUNT_REGISTER_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             ///注册成功后赋值用户信息
             if (dicData)
             {
                 //把字典传给单例
                 [[PublicValue shareValue].dicUserInfo removeAllObjects];
                 [[PublicValue shareValue].dicUserInfo setDictionary:dicData];
                 [PublicValue shareValue].isLogin = YES;
             }
             if (getRegisterBlock)
             {
                 getRegisterBlock(dicData);
             }
             
             //注册后获取红点状态
             BOOL isRead= [ChatViewController propeytyMessageIsRead];
             
             [[NSNotificationCenter defaultCenter]postNotificationName:@"PropertyMessageNofication" object:nil userInfo:@{@"isRead":@(isRead)}];
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"注册失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage duration:2];
             if (getRegisterBlock)
             {
                 getRegisterBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"注册出错！";
         [HUD hide:YES afterDelay:1];
         if (getRegisterBlock)
         {
             getRegisterBlock(nil);
         }
     }
     ];
    
}

#pragma mark 3.用户注册验证码发送
/**
 *  用户注册验证码获取接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strPhone 注册账户的手机号，用来接收验证码
 *  @param block    返回验证码信息 如果返回值为空则获取失败 获取成功的字段：phone:手机号码,  
 *                  VerifCode:发送到手机端的验证码值
 */
-(void)getVerifCode:(UIView *)viewBack UserPhone:(NSString *)strPhone
        ResultBlock:(void(^)(BOOL isSend))block
{
    //例:phone=15920545759
    getVerifCodeBlock=nil;
    getVerifCodeBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取验证码..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    //    [parameters setObject:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:strPhone?strPhone:@"" forKey:@"phone"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_SEND_MESSAGE_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         NSString *strTip=nil;
         switch (intResult)
         {
             case 0:
             {
                 [HUD hide:YES];
                 strTip=nil;
                 if (getVerifCodeBlock)
                 {
                     getVerifCodeBlock(YES);
                 }
             }
                 break;
             case 601:
             {
                 strTip=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
                 if (!strTip||[strTip isEqualToString:@""])
                 {
                     strTip=@"请一分钟后再发送获取短信码";
                 }
             }
                 break;
             case 602:
             {
                 strTip=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
                 if (!strTip||[strTip isEqualToString:@""])
                 {
                     strTip=@"30分钟内最多只能发送10次短信！";
                 }
             }
                 break;
             default:
             {
                 strTip=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
                 if (!strTip||[strTip isEqualToString:@""])
                 {
                     strTip=@"获取验证码失败！";
                 }
             }
                 break;
         }
         if (strTip)
         {
             [SVProgressHUD showErrorWithStatus:strTip];
             if (getVerifCodeBlock)
             {
                 getVerifCodeBlock(NO);
             }
         }        
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取验证码出错！";
         [HUD hide:YES afterDelay:1];
         if (getVerifCodeBlock)
         {
             getVerifCodeBlock(NO);
         }
     }
     ];
}

#pragma mark 4.用户首页接口
/**
 *  用户首页接口 显示用户的一些信息，比如收藏店铺数量、关注等
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strPhone 账号 手机号或者都要id
 *  @param block    返回用户信息 如果返回值为nil则获取失败
 *                  返回值类型：name:姓名或昵称， imageId:头相图片Id,
 *                  attentionUsersNum:关注用户数, attentionMerchantNum : 关注商铺数,  usersfans: 粉丝数
 */
-(void)getUserHome:(UIView *)viewBack UserPhone:(NSString *)strPhone
        ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    //例:phone=15920545759
    getUserHomeBlock=nil;
    getUserHomeBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取信息..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
//    [parameters setObject:strPhone?strPhone:@"" forKey:@"phone"];
    manager.securityPolicy.allowInvalidCertificates = YES;
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_ACCOUNT_INDEX_FOR_SERVER(strPhone) parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (getUserHomeBlock)
             {
                 getUserHomeBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"获取用户首页信息失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage duration:2];
             if (getUserHomeBlock)
             {
                 getUserHomeBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取用户首页信息出错！";
         [HUD hide:YES afterDelay:1];
         if (getUserHomeBlock)
         {
             getUserHomeBlock(nil);
         }
     }
     ];
    
}

#pragma mark 5.用户个人信息查看显示
/**
 *  用户个人信息查看
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回block 包含用户信息，如果返回值为nil则获取失败
 *                  返回值类型：Id:用户表主健Id,  name:姓名或昵称， imageId:头相图片Id,  sex:性别(1:男,2:女),
 *                  address:地址,  phone: 手机号码
 */
-(void)getUserInformation:(UIView *)viewBack ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    //例:phone=15920545759
    getUserInformationBlock=nil;
    getUserInformationBlock=[block copy];
    
    if (viewBack)
    {
//        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
//        HUD.delegate=self;
//        HUD.labelText=@"正在获取用户信息..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"account"]);
    if (strAccountId)
    {
        [parameters setObject:strAccountId forKey:@"dyId"];
    }
    //    [parameters setObject:strPhone?strPhone:@"" forKey:@"phone"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_ACCOUNT_SHOW_FOR_SERVER(strAccountId) parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             [HUD hide:YES];
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (getUserInformationBlock)
             {
                 getUserInformationBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"获取用户信息失败！";
             }
             HUD.labelText=strMessage;
             [HUD hide:YES afterDelay:1];
             if (getUserInformationBlock)
             {
                 getUserInformationBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取用户信息出错！";
         [HUD hide:YES afterDelay:1];
         if (getUserInformationBlock)
         {
             getUserInformationBlock(nil);
         }
     }
     ];
    
}

#pragma mark 6.用户个人信息设置编辑
/**
 *  用户个人信息的设置编辑
 *
 *  @param viewBack      提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param intType       type为就不同字段更新不同类型(1:更新昵称类型,2:更新性别类型(1:男,2:女),3:更新地址类型,4:更新手机号,5:更新密码)。
 *  @param strFieldValue fieldValue表示更新的字段值
 *  @param strOldPwd     如果是改密码，则需要传入原密码值 如果不是则此参数为nil
 *  @param block         返回block 如果返回值为nil则更失败
 *                       返回值备注：Id:用户表主健Id,  name:姓名或昵称， imageId:头相图片Id,  sex:性别(1:男,2:女),
 *                       address:地址,  phone: 手机号码, pwd:密码
 */
-(void)updateUserInformation:(UIView *)viewBack UpdateType:(int)intType
                  FieldValue:(NSString *)strFieldValue OldPassWord:(NSString *)strOldPwd
                 ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    //例:accountId=1&type=1&fieldValue=王五
//    accountId:表示用户表主健Id
//    type为就不同字段更新不同类型(1:更新昵称类型,2:更新性别类型(1:男,2:女),3:更新地址类型,4:更新手机号,5:更新密码)。
//    fieldValue表示更新的字段值
    updateUserInformationBlock=nil;
    updateUserInformationBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在修改..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"id"]);
    if (strAccountId)
    {
        [parameters setObject:strAccountId forKey:@"accountId"];
    }
    [parameters setObject:[NSString stringWithFormat:@"%d",intType] forKey:@"type"];
    //如果是修改密码需要加密
    if (intType==5)
    {
        [parameters setObject:[PublicValue md5:strFieldValue] forKey:@"fieldValue"];
        [parameters setObject:[PublicValue md5:strOldPwd] forKey:@"pwd"];
    }
    else if (intType==1)
    {
        [parameters setObject:[strFieldValue base64EncodedString] forKey:@"fieldValue"];
    }
    else
    {
        [parameters setObject:strFieldValue forKey:@"fieldValue"];
    }
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_ACCOUNT_EDIT_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (updateUserInformationBlock)
             {
                 updateUserInformationBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"修改信息失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage duration:2];
             if (updateUserInformationBlock)
             {
                 updateUserInformationBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"修改信息出错！";
         [HUD hide:YES afterDelay:1];
         if (updateUserInformationBlock)
         {
             updateUserInformationBlock(nil);
         }
     }
     ];
    
}


#pragma mark 12.C端城市定位热门城市接口
/**
 *  C端城市定位热门城市接口 获取热门城市列表
 *
 *  @param viewBack  提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param intIsHost 是否是热门 isHost=1 (1:热门城市，2：非热门城市)
 *  @param block     返回block 如果返回值为nil则获取失败
 *                   返回值备注：Id:城市Id,  name:城市名称
 */
-(void)getHostCity:(UIView *)viewBack IsHost:(int)intIsHost ResultBlock:(void(^)(NSArray *arrCity))block
{
    //isHost=1 (1:热门城市，2：非热门城市)
    
    getHostCityBlock=nil;
    getHostCityBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取热门城市列表..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:[NSString stringWithFormat:@"%d",intIsHost] forKey:@"isHost"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_PCD_HOSTPCD_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             //获取优惠列表数组
             NSArray *arrData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (getHostCityBlock)
             {
                 getHostCityBlock(arrData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage]) {
                 strMessage=@"获取列表失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage duration:2];
             if (getHostCityBlock)
             {
                 getHostCityBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取列表出错！";
         [HUD hide:YES afterDelay:1];
         if (getHostCityBlock)
         {
             getHostCityBlock(nil);
         }
     }
     ];
}


#pragma mark 21.图片上传接口
/**
 *  图片上传的接口 商家选取优惠图片时就上传服务端，服务端会返回相对应的id和服务端上的图片地址
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strPath  需要上传的图片的本地地址 沙盒里的地址
 *  @param block    返回block  如果返回值为nil则上传失败 
 *  @param 返回值备注 "imageId":"1,2,3",//图片ID          新增或修改需回传给服务端
 *                  "imageUrl":"http://192.168.200.90:9002/upload/i.jpg,
 *                  http://192.168.200.90:9002/upload/2.jpg"
 *                  图片URL    新增或修改需回传给服务端
 */
-(void)uploadFileOrImageToServer:(UIView *)viewBack ImageFilePath:(NSString *)strPath
                     ResultBlock:(void(^)(NSDictionary *dicOneSale))block
{
    
    uploadFileOrImageBlock=nil;
    uploadFileOrImageBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在上传图片..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
//    [manager.requestSerializer setValue:@"application/soap+xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    AFHTTPRequestOperation  * afRequestOperation =
    [manager POST:URL_UPLOAD_IMAGE_OR_FILE_TO_SERVER parameters:parameters constructingBodyWithBlock:
     ^(id<AFMultipartFormData> formData)
     {
         if (FILE_IS_EXIST(strPath))
         {
             NSError *error=nil;
             BOOL isUpload=[formData appendPartWithFileURL:[NSURL fileURLWithPath:strPath] name:@"image" error:&error];
             NSLog(@"%@",error);
             if (isUpload)
             {
                 NSLog(@"上传成功");
             }
         }
     }
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)//上传成功block
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (uploadFileOrImageBlock)
             {
                 uploadFileOrImageBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage]) {
                 strMessage=@"上传图片失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage duration:2];
             if (uploadFileOrImageBlock)
             {
                 uploadFileOrImageBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)//上传失败block
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"上传图片出错！";
         [HUD hide:YES afterDelay:1];
         if (uploadFileOrImageBlock)
         {
             uploadFileOrImageBlock(nil);
         }
     }
     ];
    
    //上传进度block
    [afRequestOperation setUploadProgressBlock:
     ^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite)
     {
         
         HUD.mode=MBProgressHUDModeAnnularDeterminate;
         HUD.progress=totalBytesWritten/totalBytesExpectedToWrite;
     }
     ];
    
}


#pragma mark 25.全国省市区接口.
/**
 *  获取省市区的接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回block 如果返回值为nil则获取失败
 */
-(void)getPCDListForServer:(UIView *)viewBack ResultBlock:(void (^)(NSArray *arrPCD))block
{
    getPCDListBlock=nil;
    getPCDListBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取省市区..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:@"10000" forKey:@"pageSize"];
    [parameters setObject:@"1" forKey:@"page"];
    
    [parameters setValue:@"2" forKey:@"levelNum"];//1:省   2:市    3:区
    
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_PCD_FIND_PCD_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             NSArray *arrData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (getPCDListBlock)
             {
                 getPCDListBlock(arrData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"获取省市区失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage duration:2];
             if (getPCDListBlock)
             {
                 getPCDListBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取省市区出错！";
         [HUD hide:YES afterDelay:1];
         if (getPCDListBlock)
         {
             getPCDListBlock(nil);
         }
     }
     ];

}


#pragma mark 30.获取版本更新的接口
/**
 *  获取版本更新 根据返回的strDownURL下载链接判断是否有更新，如果为nil则没更新，否则有更新
 *
 *  @param backView 提示框的父view 默认传入self.view 如果传入的view为nil，则不显示提示框
 *  @param block    返回获取版本的结果 如果返回的值不为空，则是下载链接地址，直接跳转到此地址就可以更新版本
 */
-(void)getVersionForServer:(UIView *)backView VersionBlock:(void(^)(NSString *strDownURL))block
{
    
    getVersionBlock=nil;
    getVersionBlock=[block copy];
    if (backView)
    {
        HUD=[MBProgressHUD showHUDAddedTo:backView animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在检查更新..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    [parameters setObject:@"ios" forKey:@"mobileType"];
    [parameters setObject:@"2" forKey:@"productType"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [manager POST:URL_UPDATE_VERSION_FOR_SERVER parameters:parameters success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         
         NSString *strFileAddress=nil;
         NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:@"data"]);
//         NSNumber *result=[responseObject objectForKey:@"result"];
         
         if (dicData)
         {
             @try
             {
                 //获取本app的版本号
                 float appVersion = [[[[NSBundle mainBundle] infoDictionary]
                                      objectForKey:@"CFBundleShortVersionString"] floatValue];
                 //服务端版本号
                 float netVersion=[[dicData objectForKey:@"versionNum"] floatValue];
                 //如果服务端版本号大于本地的就赋值下载地址
                 if (netVersion>appVersion)
                 {
                     strFileAddress=[NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@",[dicData objectForKey:@"fileAddress"]];
                 }
             }
             @catch (NSException *exception) {
                 
             }
             @finally {
                 
             }
             
         }
//         HUD.labelText=@"";
         [HUD hide:YES];
         if (getVersionBlock) {
             getVersionBlock(strFileAddress);
         }
         
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         HUD.labelText=@"获取版本失败";
         [HUD hide:YES afterDelay:1];
         NSLog(@"Error: %@", error);
     }
     ];
}


#pragma mark 32.短信验证码下发接口
/**
 *  短信验证码下发接口
 *
 *  @param viewBack 提示框的父view 默认传入self.view 如果传入的view为nil，则不显示提示框
 *  @param strPhone 注册时的手机号
 *  @param type     验证码的类型 安居门卫注册1;业主申请2;物业发送给业主3;用户安全度. 4;业主未接来电下发短信5
 *  @param block    返回block 如果返回值为NO则获取失败 否则获取成功
 */
-(void)getSendMessage:(UIView *)viewBack UserPhone:(NSString *)strPhone Type:(int)type
        ResultBlock:(void(^)(BOOL isSend))block
{
    //例:phone=15920545759
    getSendMessageBlock=nil;
    getSendMessageBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取验证码..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    //    [parameters setObject:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:strPhone?strPhone:@"" forKey:@"phone"];
    [parameters setObject:[NSString stringWithFormat:@"%d",type] forKey:@"type"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_SEND_MESSAGE_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             [HUD hide:YES];
//             NSDictionary *dicData=[responseObject objectForKey:DATA_FROM_SERVER];
             if (getSendMessageBlock)
             {
                 getSendMessageBlock(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"获取验证码失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage duration:2];
             if (getSendMessageBlock)
             {
                 getSendMessageBlock(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取验证码出错！";
         [HUD hide:YES afterDelay:1];
         if (getSendMessageBlock)
         {
             getSendMessageBlock(NO);
         }
     }
     ];
    
}

#pragma mark 33.C端意见反馈接口.
/**
 *  C端意见反馈接口
 *
 *  @param viewBack     提示框的父view 默认传入self.view 如果传入的view为nil，则不显示提示框
 *  @param strContent   反馈的内容信息
 *  @param strContacWay 反馈人留下的联系方式
 *  @param strCreaterId 反馈者的id
 *  @param intType      类型 暂时默认值填”1“(表示导购平台的)
 *  @param block        返回block 如果返回YES则反馈成功 否则反馈失败
 */
-(void)sendFeedBack:(UIView *)viewBack Content:(NSString *)strContent ContactWay:(NSString *)strContacWay
          CreaterID:(NSString *)strCreaterId Type:(int)intType ResultBlock:(void(^)(BOOL isSend))block
{
//    content : 反馈内容 ，一千字以内，必需，
//    contactWay : 联系方式， ，
//createrId: 反馈者id ，
//    type ： 类型，必需，暂时默认值填”1“(表示导购平台的)
//
    
    sendFeedBackBlock=nil;
    sendFeedBackBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在发送反馈意见..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    //    [parameters setObject:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:strContent?strContent:@"" forKey:@"content"];
    if (strContacWay)
    {
        [parameters setObject:strContacWay forKey:@"contactWay"];
    }
    if (strCreaterId)
    {
        [parameters setObject:strCreaterId forKey:@"createrId"];
    }
    [parameters setObject:[NSString stringWithFormat:@"%d",intType] forKey:@"type"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_FEEDBACK_SEND_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             //             NSDictionary *dicData=[responseObject objectForKey:DATA_FROM_SERVER];
             if (sendFeedBackBlock)
             {
                 sendFeedBackBlock(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"发送反馈失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage duration:2];
             if (sendFeedBackBlock)
             {
                 sendFeedBackBlock(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"发送反馈出错！";
         [HUD hide:YES afterDelay:1];
         if (sendFeedBackBlock)
         {
             sendFeedBackBlock(NO);
         }
     }
     ];
    
}

#pragma mark 34.个人设置信息头相更新.
/**
 *  个人头像信息设置更新接口
 *
 *  @param viewBack     提示框的父view 默认传入self.view 如果传入的view为nil，则不显示提示框
 *  @param strImageId   头像图片id
 *  @param strImagePath 头像图片路径
 *  @param block        返回block 如果返回为nil则更新失败 
 */
-(void)setAccountHeadImage:(UIView *)viewBack ImageID:(NSString *)strImageId
                 ImagePath:(NSString *)strImagePath ResultBlock:(void(^)(NSDictionary *dicResult))block
{
//    {
//        “accountId” : ”1”，
//        “imageId” : “1”,
//        “imagePath” : “http://192....../a.jpg”
//    }都是必须输入项.
    
    
    setAccountHeadImageBlock=nil;
    setAccountHeadImageBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在设置头像..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    //    [parameters setObject:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"id"]);
    if (strAccountId)
    {
        [parameters setObject:strAccountId forKey:@"accountId"];
    }
    [parameters setObject:strImageId?strImageId:@"" forKey:@"imageId"];
    [parameters setObject:strImagePath?strImagePath:@"" forKey:@"imagePath"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_SET_ACCOUNT_HEADIMAGE_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             [HUD hide:YES];
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (setAccountHeadImageBlock)
             {
                 setAccountHeadImageBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"设置头像失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage duration:2];
             if (setAccountHeadImageBlock)
             {
                 setAccountHeadImageBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"设置头像出错！";
         [HUD hide:YES afterDelay:1];
         if (setAccountHeadImageBlock)
         {
             setAccountHeadImageBlock(nil);
         }
     }
     ];
    
}

#pragma mark 获取首页图文更新信息 并根据用户选择是否下载
/**
 *  获取首页图文是否有更新信息
 *
 *  @param intVersion  图文版本号，用来与服务端区分是否有更新
 *  @param intPage     页数 获取的页数 默认是第一页
 *  @param intPageSize 每页多少条
 *  @param block       返回获取到的图文信息 如果有更新则提示 并返回更新图文的大小
 */
-(void)getHomeImagesUpdate:(int)intVersion Page:(int)intPage PageSize:(int)intPageSize
               ResultBlock:(void(^)(BOOL isUpdate,long updateSize))block
{
    [self getHomeImages:intVersion Page:intPage PageSize:intPageSize ResultBlock:^(NSArray *arrImages)
    {
        if (GET_OBJECT_OR_NULL(arrImages))
        {
            long imageSize=0;
            for (NSDictionary *dicOneImage in arrImages)
            {
                long oneSize=[[dicOneImage objectForKey:@"size"] longValue];
                imageSize+=oneSize;
            }
            if (imageSize>0&&block)
            {
                block(YES,imageSize);
            }
        }
    }];
    
}

/**
 *  根据用户选择下载首页图文信息 并保存到数据库
 *
 *  @param intVersion  图文版本号
 *  @param intPage     页数 第几页
 *  @param intPageSize 每页多少条数据
 *  @param block       返回是否下载并保存成功 返回YES则保存成功
 */
-(void)downHomeImages:(int)intVersion Page:(int)intPage PageSize:(int)intPageSize
          ResultBlock:(void(^)(BOOL isSave))block
{
    
    [self getHomeImages:intVersion Page:intPage PageSize:intPageSize ResultBlock:^(NSArray *arrImages)
     {
         if (GET_OBJECT_OR_NULL(arrImages))
         {
//             NSMutableDictionary *dicImageData=[[NSMutableDictionary alloc] init];
             NSMutableArray *arrImageData=[[NSMutableArray alloc] init];
             //GCD多线程下载图片缓存
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                            {
                                //循环下载图片
                                for (int i=0; i<arrImages.count; i++)
                                {
                                    NSDictionary *dicOneImage=[arrImages objectAtIndex:i];
//                                    NSString *strImageId=[dicOneImage objectForKey:SQLITE_IMAGES_CULUMN_IMAGE_ID];
                                    //获取图片路径
                                    NSString *strImageUrl=[dicOneImage objectForKey:SQLITE_IMAGES_CULUMN_IMAGE_PATH];
                                    if (strImageUrl)
                                    {
                                        //根据路径下载图片
                                        NSURL * url = [NSURL URLWithString:strImageUrl];
                                        NSData *dataImage = [NSData dataWithContentsOfURL:url];
                                        if (dataImage)
                                        {
//                                            [dicImageData setObject:dataImage forKey:strImageId];
                                            [arrImageData addObject:dataImage];
                                        }
                                        
                                    }
                                }
                                ///如果出现数量不相等则返回
                                if (arrImages.count!=arrImageData.count)
                                {
                                    return ;
                                }
                                dispatch_async(dispatch_get_main_queue(), ^
                                               {
                                                   int lastIndex=[[PublicValue getDataFromLocal:LOCAL_KEY_FOR_HOME_IMAGE_LAST_INDEX] intValue];
                                                   lastIndex=(lastIndex>=0&&lastIndex<10)?lastIndex:0;
                                                   
//                                                   //循环插入数据库
//                                                   for (int i=0; i<arrImages.count; i++)
//                                                   {
//                                                       lastIndex++;
//                                                       lastIndex=lastIndex<10?:0;
//                                                       //获取单个图文信息
//                                                       NSDictionary *dicOneImage=[arrImages objectAtIndex:i];
//                                                       //获取图文id
//                                                       NSString *strImageId=[dicOneImage objectForKey:SQLITE_IMAGES_CULUMN_IMAGE_ID];
//                                                       //根据id获取图片data
//                                                       NSData *dataImage=[dicImageData objectForKey:strImageId];
//                                                       //保存到数据库
//                                                       [sqlOper insertHomeImages:dicOneImage ImageData:dataImage ID:lastIndex+1];
//                                                   }
//                                                   [PublicValue saveDataToLocal:[NSString stringWithFormat:@"%d",lastIndex] KEY:LOCAL_KEY_FOR_HOME_IMAGE_LAST_INDEX];
                                                   
                                                   
                                                   
                                                   if (block)
                                                   {
                                                       block([[SqliteOperation defaultSqlite] insertHomeImages:arrImages ImageData:arrImageData]);
                                                       [SVProgressHUD showSuccessWithStatus:@"图文更新完成!"];
//                                                       NSLog(@"图文更新下载完成");
                                                   }
                                               });
                            });
         }
     }];

}

/**
 *  联网获取服务端的图文信息
 *
 *  @param intVersion  图文版本号
 *  @param intPage     页数 第几页
 *  @param intPageSize 每页多少条
 *  @param block       返回获取到的图文数组
 */
-(void)getHomeImages:(int)intVersion Page:(int)intPage
            PageSize:(int)intPageSize ResultBlock:(void(^)(NSArray *arrImages))block
{
    //    version=1&type=1&pageSize=10&page=0
    //    version图文版本号（缓存在客户端的最大版本号），type 图片尺寸（1：480*800,  2：720*1280,  3：1080*1920,    4：640*1136,5：640*960）
    //    接口将匹配是否有此版本，有则不返回结果，没有则返回服务端的最大版本的信息
    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:[NSString stringWithFormat:@"%d",intVersion] forKey:@"version"];
    int intType=5;
    //判断屏幕大小 取不同大小图片
    if (kDECEIVE_HEIGHT>480)
    {
        intType=4;
    }
    if (kDECEIVE_HEIGHT>568)
    {
        intType=3;
    }
    [parameters setObject:[NSString stringWithFormat:@"%d",intType] forKey:@"type"];
    [parameters setObject:[NSString stringWithFormat:@"%d",intPage] forKey:@"page"];
    [parameters setObject:[NSString stringWithFormat:@"%d",intPageSize] forKey:@"pageSize"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_GET_HOME_IMAGES_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             [HUD hide:YES];
             //获取图文列表数组
             NSArray *arrData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (block)
             {
                 block(arrData);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
     }
     ];
    
    
}


#pragma mark



#pragma mark 签到或分享加分的接口

/**
 *  签到或分享获取积分的接口
 *
 *  @param viewBack     提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param intType      （type:2签到，其他:分享）
 *  @param block        返回block 如果返回值为NO，则获取积分失败
 */
-(void)setSignInToServer:(UIView *)viewBack Type:(int)intType ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    //    dyId=66&type=1
    //    dyId用户表都要Id,（type:1签到，2:分享）
    
    
    setSignInOrShareBlock=nil;
    setSignInOrShareBlock=[block copy];
    
    if (intType==2)
    {
        [ANStatusBarHUD showWithStatusBar:@"正在签到..."];
    }
    else
    {
//        [ANStatusBarHUD showWithStatusBar:@"正在获取分享积分..."];
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"account"]);
    if (strAccountId)
    {
        [parameters setObject:strAccountId forKey:@"dyId"];
    }
    
    [parameters setObject:[NSString stringWithFormat:@"%d",intType] forKey:@"type"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_SET_SIGN_OR_SHARE_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         ///签到模式
         if (intType==2)
         {
             //等于0 请求成功
             switch (intResult)
             {
                 case 0://成功
                 {
                     [ANStatusBarHUD hideWithSuccess:@"签到成功"];
                     NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
                     if (setSignInOrShareBlock)
                     {
                         setSignInOrShareBlock(dicData);
                     }
                 }
                     break;
                 case 1://表示一个自然日内只能签到一次
                 {
                     [ANStatusBarHUD hideWithRightNow];
                     [SVProgressHUD showErrorWithStatus:@"今天已签到，明天再来哦"];
                     if (setSignInOrShareBlock)
                     {
                         setSignInOrShareBlock(nil);
                     }
                 }
                     break;
                 default:
                 {
                     [ANStatusBarHUD hideWithRightNow];
                     NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
                     if ([PublicValue isEmpty:strMessage])
                     {
                         strMessage=@"签到失败！";
                     }
                     [SVProgressHUD showErrorWithStatus:strMessage duration:2];
                     if (setSignInOrShareBlock)
                     {
                         setSignInOrShareBlock(nil);
                     }
                 }
                     break;
             }
         }
         else
         {
             //等于0 请求成功
             switch (intResult)
             {
                 case 0://成功
                 {
                     [ANStatusBarHUD showSuccessWithStatusBar:@"分享成功"];
                     NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
                     if (setSignInOrShareBlock)
                     {
                         setSignInOrShareBlock(dicData);
                     }
                 }
                     break;
                 case 1:
                 {
//                     [ANStatusBarHUD showErrorWithStatusBar:@"今天分享奖励已满，明天再来哦！"];
                 }
                     break;
                 default:
                 {
//                     [ANStatusBarHUD showErrorWithStatusBar:@"获取分享积分奖励失败！"];
                 }
                     break;
             }
         }
         
//         [ANStatusBarHUD hideWithRightNow];
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         if (intType==2)
         {
             [ANStatusBarHUD hideWithError:@"签到出错！"];
             if (setSignInOrShareBlock)
             {
                 setSignInOrShareBlock(nil);
             }
         }
         else
         {
//             [ANStatusBarHUD hideWithError:@"获取分享积分奖励出错！"];
         }
     }
     ];
}

#pragma mark 获取我的房间列表
/**
 *  获取我的房间列表 根据小区id获取对应的房间列表 小区号为空则返回全部的房间
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strCommunityId communityId不是必须「当不传值时，查询出所有小区我的房子」
 *  @param block          返回block 如果返回值为空则获取失败
 */
-(void)getRoomListForServer:(UIView *)viewBack CommunityId:(NSString *)strCommunityId
                ResultBlock:(void(^)(NSArray *arrList))block
{
    //返回参数
    //    status：审核状态（1：表示审核通过，2表示审核未通过[物业拒绝],  3:表示审核中，4：未提交审核）
    //id:房间主健id,communityId:小区id ,  communityName小区名称,  accountId:登录用户的id,
//    houseNum:房子号,houseCode:房间编号，name:业主名称,phone：业主手机
    
    //传入参数
//    accountId=66&communityId=20
//    accountId用户id[必须],  communityId不是必须「当不传值时，查询出所有小区我的房子」

    
    getRoomListBlock=nil;
    getRoomListBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取房间列表..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    //添加用户id
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"account"]);
    if (strAccountId)
    {
        [parameters setObject:strAccountId forKey:@"dyId"];
    }
    if (strCommunityId)
    {
        [parameters setObject:strCommunityId forKey:@"communityId"];
    }
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_GET_ROOM_LIST_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             //获取优惠列表数组
             NSArray *arrData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (!arrData||arrData.count<=0)
             {
                 [SVProgressHUD showErrorWithStatus:@"暂时还没有添加小区房号"];
             }
             //             NSArray *arrList=[arrData objectAtIndex:0];//[dicData objectForKey:@"list"];
             if (getRoomListBlock&&arrData)
             {
                 getRoomListBlock(arrData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"获取房间列表失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (getRoomListBlock)
             {
                 getRoomListBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取房间列表出错！";
         [HUD hide:YES afterDelay:1];
         if (getRoomListBlock)
         {
             getRoomListBlock(nil);
         }
     }
     ];
    
    
}


#pragma mark 获取我的授权人列表
/**
 *  根据用户id 查询我的授权人列表
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strHouseId     房间的主键id 查看哪个房间的授权人就传入哪个主键
 *  @param block          返回block 如果返回值为空则获取失败
 */
-(void)getEmpowerListForServer:(UIView *)viewBack HouseID:(NSString *)strHouseId
                   ResultBlock:(void(^)(NSArray *arrList))block
{
    getEmpowerListBlock=nil;
    getEmpowerListBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取授权人列表..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    //添加用户id
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"account"]);
    if (strAccountId)
    {
        [parameters setObject:strAccountId forKey:@"dyId"];
    }
    [parameters setObject:strHouseId?strHouseId:@"" forKey:@"houseId"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_GET_EMPOWER_LIST_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             //获取优惠列表数组
             NSArray *arrData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (!arrData||arrData.count<=0)
             {
                 [SVProgressHUD showErrorWithStatus:@"暂时还没有添加授权人"];
             }
             //             NSArray *arrList=[arrData objectAtIndex:0];//[dicData objectForKey:@"list"];
             if (getEmpowerListBlock&&arrData)
             {
                 getEmpowerListBlock(arrData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"获取授权人列表失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (getEmpowerListBlock)
             {
                 getEmpowerListBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取授权人列表出错！";
         [HUD hide:YES afterDelay:1];
         if (getEmpowerListBlock)
         {
             getEmpowerListBlock(nil);
         }
     }
     ];
}


#pragma mark 添加我的授权人
/**
 *  根据用户id 查询我的授权人列表
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param arrEmpower     数组 授权人数组
 *  @param block          返回block 如果返回值为空则获取失败
 */
-(void)addEmpowerToServer:(UIView *)viewBack EmpowerList:(NSMutableArray *)arrEmpower
              ResultBlock:(void(^)(BOOL isSave))block
{
    addEmpowerBlock=nil;
    addEmpowerBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在添加授权人..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    //添加用户id
    NSString *jsonString = [[NSString alloc] initWithData:[PublicValue toJSONData:arrEmpower]
                                                                        encoding:NSUTF8StringEncoding];
    [parameters setObject:jsonString forKey:@"data"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_ADD_EMPOWER_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             
             if (addEmpowerBlock)
             {
                 addEmpowerBlock(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"添加授权失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (addEmpowerBlock)
             {
                 addEmpowerBlock(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"添加授权出错！";
         [HUD hide:YES afterDelay:1];
         if (addEmpowerBlock)
         {
             addEmpowerBlock(NO);
         }
     }
     ];
}

#pragma mark 删除对应授权人
/**
 *  根据授权人id 删除对应的授权人
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strEmpowerId   id 授权人id
 *  @param strHouseId     房间id
 *  @param block          返回block 如果返回值为空则删除失败
 */
-(void)deleteEmpowerToServer:(UIView *)viewBack EmpowerId:(NSString *)strEmpowerId HouseID:(NSString *)strHouseId
              ResultBlock:(void(^)(BOOL isDelete))block
{
    deleteEmpowerBlock=nil;
    deleteEmpowerBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在删除授权人..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:strHouseId?strHouseId:@"" forKey:@"houseId"];
    [parameters setObject:strEmpowerId?strEmpowerId:@"" forKey:@"id"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_DELETE_EMPOWER_FOR_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             
             if (deleteEmpowerBlock)
             {
                 deleteEmpowerBlock(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"删除授权失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (deleteEmpowerBlock)
             {
                 deleteEmpowerBlock(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"删除授权出错！";
         [HUD hide:YES afterDelay:1];
         if (deleteEmpowerBlock)
         {
             deleteEmpowerBlock(NO);
         }
     }
     ];
}


#pragma mark 个性签名修改
/**
 *  用户个人签名的设置
 *
 *  @param viewBack      提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strSignature  strSignature表示更新的字段值
 *  @param block         返回block 如果返回值为no则更新失败
 *
 */
-(void)editSignatureToServer:(UIView *)viewBack Signature:(NSString *)strSignature
                 ResultBlock:(void(^)(BOOL isSave))block
{
//    dyId=1&signature=明天一定要好好努力.....
//    参数signature请base64加密传入
    
    
    editSignatureBlock=nil;
    editSignatureBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在修改签名..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"account"]);
    if (strAccountId)
    {
        [parameters setObject:strAccountId forKey:@"dyId"];
    }
    [parameters setObject:strSignature?:@"" forKey:@"signature"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_EDIT_SIGNATURE_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:YES afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             if (editSignatureBlock)
             {
                 editSignatureBlock(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"修改签名失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (editSignatureBlock)
             {
                 editSignatureBlock(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"修改签名出错！";
         [HUD hide:YES afterDelay:1];
         if (editSignatureBlock)
         {
             editSignatureBlock(NO);
         }
     }
     ];
    
}

#pragma mark 个人保镖/紧急救助个人基本资料展现接口
/**
 *  个人保镖/紧急救助个人基本资料展现接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回值block 如果返回为nil则获取失败
 */
-(void)getBasicInfoForServer:(UIView *)viewBack ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    getBasicInfoBlock=nil;
    getBasicInfoBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取基本资料..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"account"]);
    //    [parameters setObject:strAccountId forKey:@"accountId"];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager GET:URL_GET_BASICINFO_FOR_SERVER(strAccountId) parameters:parameters
         success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:YES afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (getBasicInfoBlock)
             {
                 getBasicInfoBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"获取失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (getBasicInfoBlock)
             {
                 getBasicInfoBlock(nil);
             }
         }
     }
         failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取出错！";
         [HUD hide:YES afterDelay:1];
         if (getBasicInfoBlock)
         {
             getBasicInfoBlock(nil);
         }
     }
     ];
    
}

#pragma mark 个人保镖/紧急救助个人基本资料保存接口
/**
 *  个人保镖/紧急救助个人基本资料保存接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param dicInfo  基本资料集合 字典
 *  @param block    返回值block 如果返回为nil则保存失败
 */
-(void)saveBasicInfoToServer:(UIView *)viewBack BasicInfo:(NSDictionary *)dicInfo
                 ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    saveBasicInfoBlock=nil;
    saveBasicInfoBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在保存基本资料..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] initWithDictionary:dicInfo];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"account"]);
    if (strAccountId)
    {
        [parameters setObject:strAccountId forKey:@"dyId"];
    }
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_SAVE_BASICINFO_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:YES afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (saveBasicInfoBlock)
             {
                 saveBasicInfoBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"保存失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (saveBasicInfoBlock)
             {
                 saveBasicInfoBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"保存出错！";
         [HUD hide:YES afterDelay:1];
         if (saveBasicInfoBlock)
         {
             saveBasicInfoBlock(nil);
         }
     }
     ];
    
}


#pragma mark 紧急救助个人医疗信息展现接口
/**
 *  紧急救助个人医疗信息展现接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回值block 如果返回为nil则获取失败
 */
-(void)getMedicalForServer:(UIView *)viewBack ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    getMedicalBlock=nil;
    getMedicalBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取医疗信息..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"account"]);
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_GET_MEDICAL_FOR_SERVER(strAccountId) parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:YES afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (getMedicalBlock)
             {
                 getMedicalBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"获取失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (getMedicalBlock)
             {
                 getMedicalBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取出错！";
         [HUD hide:YES afterDelay:1];
         if (getMedicalBlock)
         {
             getMedicalBlock(nil);
         }
     }
     ];
    
}


#pragma mark 紧急救助个人医疗信息保存接口
/**
 *  紧急救助个人医疗信息保存接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param dicInfo  医疗信息集合 数组
 *  @param block    返回值block 如果返回为nil则保存失败
 */
-(void)saveMedicalToServer:(UIView *)viewBack MedicalInfo:(NSDictionary *)dicInfo
                 ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    saveMedicalBlock=nil;
    saveMedicalBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在保存医疗信息..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *jsonString = [[NSString alloc] initWithData:[PublicValue toJSONData:dicInfo]
                                                 encoding:NSUTF8StringEncoding];
    [parameters setObject:jsonString forKey:@"data"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_SAVE_MEDICAL_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:YES afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (saveMedicalBlock)
             {
                 saveMedicalBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"保存失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (saveMedicalBlock)
             {
                 saveMedicalBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"保存出错！";
         [HUD hide:YES afterDelay:1];
         if (saveMedicalBlock)
         {
             saveMedicalBlock(nil);
         }
     }
     ];
    
}

#pragma mark 删除医疗信息
/**
 *  根据医疗id 删除对应的医疗信息
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strMedicalId   id 医疗id
 *  @param block          返回block 如果返回值为空则删除失败
 */
-(void)deleteMedicalToServer:(UIView *)viewBack MedicalId:(NSString *)strMedicalId
                 ResultBlock:(void(^)(BOOL isDelete))block
{
    deleteMedicalBlock=nil;
    deleteMedicalBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在删除..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_DELETE_MEDICAL_TO_SERVER(strMedicalId) parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             
             if (deleteMedicalBlock)
             {
                 deleteMedicalBlock(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"删除失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (deleteMedicalBlock)
             {
                 deleteMedicalBlock(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"删除出错！";
         [HUD hide:YES afterDelay:1];
         if (deleteMedicalBlock)
         {
             deleteMedicalBlock(NO);
         }
     }
     ];
}


#pragma mark 紧急联系人信息展现接口
/**
 *  紧急联系人信息展现接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回值block 如果返回为nil则获取失败
 */
-(void)getContactersForServer:(UIView *)viewBack ResultBlock:(void(^)(NSArray *arrList))block
{
    getContactersBlock=nil;
    getContactersBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在获取紧急联系人..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"account"]);
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_GET_CONTACTERS_FOR_SERVER(strAccountId) parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:YES afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (dicData)
             {
                 NSArray *arrData=[dicData objectForKey:@"contacts"];
                 if (getContactersBlock)
                 {
                     getContactersBlock(arrData);
                 }
             }
             
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"获取失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (getContactersBlock)
             {
                 getContactersBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取出错！";
         [HUD hide:YES afterDelay:1];
         if (getMedicalBlock)
         {
             getMedicalBlock(nil);
         }
     }
     ];
    
}


#pragma mark 紧急联系人信息保存接口
/**
 *  紧急联系人信息保存接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param arrInfo  紧急联系人集合 数组
 *  @param block    返回值block 如果返回为nil则保存失败
 */
-(void)saveContactersToServer:(UIView *)viewBack ContactInfo:(NSArray *)arrInfo
               ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    saveContactersBlock=nil;
    saveContactersBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在保存紧急联系人..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    NSString *jsonString = [[NSString alloc] initWithData:[PublicValue toJSONData:arrInfo]
                                                 encoding:NSUTF8StringEncoding];
    [parameters setObject:jsonString forKey:@"data"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_SAVE_CONTACTERS_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:YES afterDelay:0];
         //返回结果状态值
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         //等于0 请求成功
         if (intResult==0)
         {
             NSDictionary *dicData=GET_OBJECT_OR_NULL([responseObject objectForKey:DATA_FROM_SERVER]);
             if (saveContactersBlock)
             {
                
                 saveContactersBlock(dicData);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"保存失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (saveContactersBlock)
             {
                 saveContactersBlock(nil);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"保存出错！";
         [HUD hide:YES afterDelay:1];
         if (saveContactersBlock)
         {
             saveContactersBlock(nil);
         }
     }
     ];
    
}

#pragma mark 删除紧急联系人接口
/**
 *  根据医疗id 删除对应的紧急联系人
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strContacterId id 紧急联系人id
 *  @param block          返回block 如果返回值为空则删除失败
 */
-(void)deleteContacterToServer:(UIView *)viewBack ContacterId:(NSString *)strContacterId
                 ResultBlock:(void(^)(BOOL isDelete))block
{
    deleteContactersBlock=nil;
    deleteContactersBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在删除..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?strToken:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_DELETE_Contacter_TO_SERVER(strContacterId) parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             
             if (deleteContactersBlock)
             {
                 deleteContactersBlock(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"删除失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (deleteContactersBlock)
             {
                 deleteContactersBlock(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"删除出错！";
         [HUD hide:YES afterDelay:1];
         if (deleteContactersBlock)
         {
             deleteContactersBlock(NO);
         }
     }
     ];
}


#pragma mark 从AppStore获取更新数据
/**
 *  从AppStore获取更新版本 根据返回block值判断是否有更新 如果返回为nil则更新失败或者没有更新版本
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回值block 如果返回值为nil则更新失败或者没有更新版本 否则返回更新版本链接
 */
-(void)getUpdateVersionForAPPStore:(UIView *)viewBack ResultBlock:(void(^)(NSString *strUrl))block
{
    getUpdateVersionForAPPStoreBlock=nil;
    getUpdateVersionForAPPStoreBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在检查更新版本..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_UPDATE_FOR_APPSTORE parameters:nil
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         NSArray *infoArray = GET_OBJECT_OR_NULL([responseObject objectForKey:@"results"]);
         if (infoArray&&[infoArray count]>0)
         {
             NSDictionary *releaseInfo = [infoArray objectAtIndex:0];
             //获取AppStore版本
             NSString *latestVersion = [releaseInfo objectForKey:@"version"];
             //获取APP在AppStore的地址
             NSString *trackViewUrl = [releaseInfo objectForKey:@"trackViewUrl"];
             //判断当前版本和AppStore的版本是否相同 不相同代表有更新
             if (![latestVersion isEqualToString:APP_CURRENT_VERSION])
             {
                 [HUD hide:YES];
                 if (getUpdateVersionForAPPStoreBlock)
                 {
                     getUpdateVersionForAPPStoreBlock(trackViewUrl);
                 }
             }
             else
             {
                 HUD.labelText=@"当前已经是最新版本！";
                 [HUD hide:YES afterDelay:1];
                 if (getUpdateVersionForAPPStoreBlock)
                 {
                     getUpdateVersionForAPPStoreBlock(nil);
                 }
             }
         }
         else
         {
             HUD.labelText=@"检查版本更新失败！";
             [HUD hide:YES afterDelay:1];
             if (getUpdateVersionForAPPStoreBlock)
             {
                 getUpdateVersionForAPPStoreBlock(nil);
             }
         }
         
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取更新版本出错！";
         [HUD hide:YES afterDelay:1];
         if (getUpdateVersionForAPPStoreBlock)
         {
             getUpdateVersionForAPPStoreBlock(nil);
         }
     }
     ];
}


#pragma mark 从fir上获取更新版本
/**
 *  检查从FIR上获取安居宝更新版本的信息
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回block 返回版本信息 如果返回nil则没有版本更新
 */
-(void)getVersionForFir:(UIView *)viewBack ResultBlock:(void(^)(NSDictionary *dicResult))block
{
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在检查更新版本..";
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager GET:URL_UPDATE_FOR_FIR parameters:nil
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         //获取FIR版本
         NSString *latestVersion = GET_OBJECT_OR_NULL([responseObject objectForKey:@"version"]);
         //判断当前版本和FIR的版本是否相同 不相同代表有更新
         if (![latestVersion isEqualToString:APP_CURRENT_BUILDING_VERSION])
         {
             [HUD hide:YES];
             [PublicValue shareValue].isUpdateVersion=YES;
             if (block)
             {
                 block(responseObject);
             }
         }
         else
         {
             HUD.labelText=@"当前已经是最新版本！";
             [HUD hide:YES afterDelay:1];
             [PublicValue shareValue].isUpdateVersion=NO;
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"获取更新版本出错！";
         [HUD hide:YES afterDelay:1];
         
     }
     ];
}


#pragma mark 安全度手机号码验证
/**
 *  安全度手机号码验证
 *
 *  @param viewBack  提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strPhone  手机号码
 *  @param strVerifi 验证码
 *  @param block     返回block 如果返回为YES则验证成功 否则失败
 */
-(void)verificationPhoneToServer:(UIView *)viewBack PhoneNum:(NSString *)strPhone
                       VerifiNum:(NSString *)strVerifi ResultBlock:(void(^)(BOOL isRight))block
{
    verificationPhoneBlock=nil;
    verificationPhoneBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在验证..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:strPhone?:@"" forKey:@"phone"];
    [parameters setObject:strVerifi?:@"" forKey:@"checkCode"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo
                                               objectForKey:@"account"]);
    [parameters setObject:strAccountId?:@"" forKey:@"dyId"];
    
    
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_VERIFICATION_PHONE_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             if (verificationPhoneBlock)
             {
                 verificationPhoneBlock(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"验证失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (verificationPhoneBlock)
             {
                 verificationPhoneBlock(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"验证出错！";
         [HUD hide:YES afterDelay:1];
         if (verificationPhoneBlock)
         {
             verificationPhoneBlock(NO);
         }
     }
     ];
}

#pragma mark 安全度邮箱账号验证
/**
 *  安全度邮箱账号验证
 *
 *  @param viewBack  提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strEmail  邮箱号码
 *  @param block     返回block 如果返回为YES则验证成功 否则失败
 */
-(void)verificationEmailToServer:(UIView *)viewBack Email:(NSString *)strEmail
                     ResultBlock:(void(^)(BOOL isRight))block
{
    verificationEmailBlock=nil;
    verificationEmailBlock=[block copy];
    
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在验证..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    NSString *strToken=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo objectForKey:@"token"]);
    [parameters setObject:strToken?:@"928e5543c3388dbd15565f8227e8de2d" forKey:@"access_token"];
    [parameters setObject:strEmail?:@"" forKey:@"email"];
    NSString *strAccountId=GET_OBJECT_OR_NULL([[PublicValue shareValue].dicUserInfo
                                               objectForKey:@"account"]);
    [parameters setObject:strAccountId?:@"" forKey:@"dyId"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_VERIFICATION_EMAIL_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             if (verificationEmailBlock)
             {
                 verificationEmailBlock(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"验证失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (verificationEmailBlock)
             {
                 verificationEmailBlock(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"验证出错！";
         [HUD hide:YES afterDelay:1];
         if (verificationEmailBlock)
         {
             verificationEmailBlock(NO);
         }
     }
     ];
}

#pragma mark 找回密码接口


/**
 *  找回密码下一步需要调用的接口 判断验证码的正确与否
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strPhone 手机号
 *  @param strCode  验证码
 *  @param block    返回是否验证成功 返回yes则验证成功 否则失败
 */
-(void)checkPhoneNextToResetPwd:(UIView *)viewBack PhoneNum:(NSString *)strPhone
                      VerifiNum:(NSString *)strCode ResultBlock:(void(^)(BOOL isRight))block
{
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在验证..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_CHECK_CODE_TO_SERVER(strPhone, strCode) parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             if (block)
             {
                 block(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"验证失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (block)
             {
                 block(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"验证出错！";
         [HUD hide:YES afterDelay:1];
         if (block)
         {
             block(NO);
         }
     }
     ];
}

/**
 *  重置密码提交接口地址
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strPhone 传入需要重置密码的手机账号
 *  @param strPwd   传入修改的密码
 *  @param block    返回接口 如果返回yes则修改成功 否则失败
 */
-(void)forgetPhoneToServer:(UIView *)viewBack PhoneNum:(NSString *)strPhone
                       ResetPwd:(NSString *)strPwd ResultBlock:(void(^)(BOOL isRight))block
{
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在提交..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    [parameters setObject:strPhone?:@"" forKey:@"phone"];
    [parameters setObject:[PublicValue md5:strPwd] forKey:@"pwd"];
    [parameters setObject:[PublicValue md5:strPwd] forKey:@"cfimPwd"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_RESET_PWD_TO_SERVER parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             if (block)
             {
                 block(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"重置密码失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (block)
             {
                 block(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"重置密码出错！";
         [HUD hide:YES afterDelay:1];
         if (block)
         {
             block(NO);
         }
     }
     ];
}

/**
 *  使用邮箱账号找回密码接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strEmail 邮箱账号
 *  @param block    返回接口 如果返回YES则成功 否则失败
 */
-(void)forgetEmailToServer:(UIView *)viewBack Email:(NSString *)strEmail
                     ResultBlock:(void(^)(BOOL isRight))block
{
    if (viewBack)
    {
        HUD=[MBProgressHUD showHUDAddedTo:viewBack animated:YES];
        HUD.delegate=self;
        HUD.labelText=@"正在提交..";
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init];
    manager.securityPolicy.allowInvalidCertificates = YES;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_FORGET_EMAIL_TO_SERVER([strEmail base64EncodedString]) parameters:parameters
          success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         HUD.mode=MBProgressHUDModeText;
         [HUD hide:NO afterDelay:0];
         
         id result=GET_OBJECT_OR_NULL([responseObject objectForKey:RESULT_FROM_SERVER]);
         int intResult=[result intValue];
         if (intResult==0)
         {
             if (block)
             {
                 block(YES);
             }
         }
         else
         {
             NSString *strMessage=GET_OBJECT_OR_NULL([responseObject objectForKey:MESSAGE_FROM_SERVER]);
             if ([PublicValue isEmpty:strMessage])
             {
                 strMessage=@"找回密码失败！";
             }
             [SVProgressHUD showErrorWithStatus:strMessage];
             if (block)
             {
                 block(NO);
             }
         }
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         HUD.mode=MBProgressHUDModeText;
         HUD.labelText=@"找回密码出错！";
         [HUD hide:YES afterDelay:1];
         if (block)
         {
             block(NO);
         }
     }
     ];
}



+ (void)getRemainingPackagesBeforeBlock:(void(^)(void))beforeBlock resuleBlock:(void(^)(BOOL isSuccessed, id result))resultBlock
{
    if (beforeBlock) {
        beforeBlock();
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    manager.securityPolicy.allowInvalidCertificates = YES;

    NSString *getPath = [REMAINING_PACKAGES stringByAppendingPathComponent:GET_OBJECT_OR_NULL([PublicValue shareValue].dicUserInfo[@"account"])];
        [manager GET:getPath parameters:@{@"access_token":[PublicValue shareValue].dicUserInfo[@"token"]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject[@"result"] integerValue] == 0 && resultBlock) {
            resultBlock(YES, responseObject);
        } else if (resultBlock) {
            resultBlock(NO, responseObject[@"message"]);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (resultBlock) {
            resultBlock(NO, @"连接服务器失败");
        }
    }];
}




#pragma mark -
#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[HUD removeFromSuperview];
	HUD = nil;
}

/**
 *  设置tag以及alias
 */
-(void)setTagsAndalias:(NSDictionary *)dicInfo
{
    
    
    
    NSMutableSet *mutableSet=[NSMutableSet setWithCapacity:0];
    if (GET_OBJECT_OR_NULL(dicInfo[@"houseList"])) {
        for (NSDictionary *dic in dicInfo[@"houseList"]) {
            [mutableSet addObject:[NSString stringWithFormat:@"%@",dic[@"communityNum"]]];
        }
        [APService setTags:mutableSet alias:[NSString stringWithFormat:@"%@%@",[AnJuConfig defaultConfig].push_Prefix,dicInfo[@"account"]] callbackSelector:nil target:nil];

    }
}

// 向服务器发送支付日志
- (void)callLogToServer
{
    UIDevice *device = [UIDevice currentDevice];
    NSString *appenv = [NSString stringWithFormat:@"%@ %@", device.model, device.systemName];
    NSString *notifyUrl = [AnJuConfig defaultConfig].aliPayRedirectPath;
    NSString *partnerID = [PublicValue shareValue].alipyDictionary[@"partnerID"];
    NSString *sign = [PublicValue shareValue].alipyDictionary[@"sign"];
    NSString *orderID = [PublicValue shareValue].alipyDictionary[@"orderID"];
    NSString *subject = [PublicValue shareValue].alipyDictionary[@"subject"];
    NSString *sellerId = [PublicValue shareValue].alipyDictionary[@"sellerID"];
    NSString *totalFee = [PublicValue shareValue].alipyDictionary[@"totalFee"];
    NSString *body = [PublicValue shareValue].alipyDictionary[@"body"];
    
    NSDictionary *params = @{
                             @"dyId":[PublicValue shareValue].dicUserInfo[@"account"],
                             @"appCaller" : @"安居宝门卫",
                             @"moduleCaller" : @"提交订单",
                             @"service" : @"mobile.securitypay.pay",
                             @"partner" : partnerID,
                             @"inputCharset" : @"utf-8",
                             @"signType" : @"RSA",
                             @"sign" : sign,
                             @"notifyUrl" : notifyUrl,
                             @"appId" : APP_CURRENT_VERSION,
                             @"appenv" : appenv,
                             @"outTradeNo" : orderID,
                             @"subject" : subject,
                             @"paymentType" : @"1",
                             @"sellerId" : sellerId,
                             @"totalFee" : totalFee,
                             @"body" : body,
                             @"itBPay" : @"30m",
                             @"showUrl" : @"m.alipay.com",
                             @"externToken" : @"externtoken",
                             @"payMethod" : @""
                             };
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager POST:URL_FOR_CALL_LOG parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Alipay Call Log Successed, result object : %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Aipay Call Log Error, error : %@", error.localizedDescription);
    }];
}


@end
