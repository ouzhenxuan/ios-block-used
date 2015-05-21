//
//  NetLinkOperation.h
//  ShoppingData
//
//  Created by ChenMacmini on 14-8-13.
//  Copyright (c) 2014年 ANJUBAO. All rights reserved.
//
//
//
//  网络操作提供接口界面 陈永昌
//



#import <Foundation/Foundation.h>
#import "PublicValue.h"
#import "MBProgressHUD.h"
#import "SqliteOperation.h"
#import "SVProgressHUD.h"
#import "Base64.h"
#import "AJBTalkProtocol.h"


@interface NetLinkOperation : NSObject<MBProgressHUDDelegate>
{

    //获取上传结果的block 直接调用 返回yes或no
    void(^getUploadFileResult)(BOOL isUpload);
    //获取上传文件结果信息的block
    void(^getUploadFileResultInfo)(NSDictionary *dicResult);
    //获取任务商店数组block 写死
    void(^getTaskForMerchant)(BOOL isDown);
    //获取任务商店数据block
    void(^getTaskForAllMerchant)(NSDictionary *dicTask);
    
    
    
    //数据库对象
    SqliteOperation *sqlOper;
    
    
    
    //提示框
    MBProgressHUD *HUD;
    
#pragma mark 接口block
    ///1.用户登录 block
    void(^getLoginResultBlock)(NSDictionary *dicResult);
    ///2.用户注册 block
    void(^getRegisterBlock)(NSDictionary *dicResult);
    ///3.用户注册验证码发送 block
    void(^getVerifCodeBlock)(BOOL isSend);
    ///4.用户首页接口 block
    void(^getUserHomeBlock)(NSDictionary *dicResult);
    ///5.用户个人信息查看显示 block
    void(^getUserInformationBlock)(NSDictionary *dicResult);
    ///6.用户个人信息设置编辑 block
    void(^updateUserInformationBlock)(NSDictionary *dicResult);
    ///12.C端城市定位热门城市接口 block
    void(^getHostCityBlock)(NSArray *arrCity);
    ///21.图片上传接口 block
    void(^uploadFileOrImageBlock)(NSDictionary *dicResult);
    ///25.获取省市区数据的block
    void(^getPCDListBlock)(NSArray *arrPCD);
    ///26.获取类别数据的block
    void(^getCategoriesListBlock)(NSArray *arrCategories);
    ///30.获取版本更新的block
    void(^getVersionBlock)(NSString *strDownURL);
    ///32.短信验证码下发接口 block
    void(^getSendMessageBlock)(BOOL isSend);
    ///33.C端意见反馈接口.
    void(^sendFeedBackBlock)(BOOL isSend);
    ///34.个人设置信息头相更新.
    void(^setAccountHeadImageBlock)(NSDictionary *dicResult);
    
    //首页图文block
    void(^getHomeImagesBlock)(BOOL isSave);
    ///签到或分享加分的接口block
    void(^setSignInOrShareBlock)(NSDictionary *dicResult);
    ///获取我的房间列表block
    void(^getRoomListBlock)(NSArray *arrList);
    ///获取我的授权人列表block
    void(^getEmpowerListBlock)(NSArray *arrList);
    ///增加我的授权人
    void(^addEmpowerBlock)(BOOL isSave);
    ///删除我的授权人的block
    void(^deleteEmpowerBlock)(BOOL isDelete);
    ///修改个性签名block
    void(^editSignatureBlock)(BOOL isSave);
    ///个人保镖/紧急救助个人基本资料展现接口block
    void(^getBasicInfoBlock)(NSDictionary *dicResult);
    ///个人保镖/紧急救助个人基本资料保存接口block
    void(^saveBasicInfoBlock)(NSDictionary *dicResult);
    ///紧急救助个人医疗信息展现接口block
    void(^getMedicalBlock)(NSDictionary *dicResult);
    ///紧急救助个人医疗信息保存接口block
    void(^saveMedicalBlock)(NSDictionary *dicResult);
    ///紧急求助个人医疗信息删除接口block
    void(^deleteMedicalBlock)(BOOL isDelete);
    ///紧急联系人信息展现接口block
    void(^getContactersBlock)(NSArray *arrList);
    ///紧急联系人信息保存接口block
    void(^saveContactersBlock)(NSDictionary *dicResult);
    ///紧急联系人信息删除接口block
    void(^deleteContactersBlock)(BOOL isDelete);
    ///从AppStore检测更新版本
    void(^getUpdateVersionForAPPStoreBlock)(NSString *strUrl);
    ///验证手机号码的block
    void(^verificationPhoneBlock)(BOOL isRight);
    ///验证邮箱的block
    void(^verificationEmailBlock)(BOOL isRight);
}

///默认初始化
+(id)defaultNetLink;


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
          ResultBlock:(void(^)(NSDictionary *dicResult))block;

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
         VerifCode:(NSString *)strVerifCode RegisterType:(int)intType ResultBlock:(void(^)(NSDictionary *dicResult))block;

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
        ResultBlock:(void(^)(BOOL isSend))block;

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
       ResultBlock:(void(^)(NSDictionary *dicResult))block;

#pragma mark 5.用户个人信息查看显示
/**
 *  用户个人信息查看
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回block 包含用户信息，如果返回值为nil则获取失败
 *                  返回值类型：Id:用户表主健Id,  name:姓名或昵称， imageId:头相图片Id,  sex:性别(1:男,2:女),
 *                  address:地址,  phone: 手机号码
 */
-(void)getUserInformation:(UIView *)viewBack ResultBlock:(void(^)(NSDictionary *dicResult))block;

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
                 ResultBlock:(void(^)(NSDictionary *dicResult))block;


#pragma mark 12.C端城市定位热门城市接口
/**
 *  C端城市定位热门城市接口 获取热门城市列表
 *
 *  @param viewBack  提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param intIsHost 是否是热门 isHost=1 (1:热门城市，2：非热门城市)
 *  @param block     返回block 如果返回值为nil则获取失败
 *                   返回值备注：Id:城市Id,  name:城市名称
 */
-(void)getHostCity:(UIView *)viewBack IsHost:(int)intIsHost ResultBlock:(void(^)(NSArray *arrCity))block;



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
                     ResultBlock:(void(^)(NSDictionary *dicOneSale))block;



#pragma mark 25.全国省市区接口.
/**
 *  获取省市区的接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回block 如果返回值为nil则获取失败
 */
-(void)getPCDListForServer:(UIView *)viewBack ResultBlock:(void (^)(NSArray *arrPCD))block;



#pragma mark 30.获取版本更新的接口
/**
 *  获取版本更新 根据返回的strDownURL下载链接判断是否有更新，如果为nil则没更新，否则有更新
 *
 *  @param backView 提示框的父view 默认传入self.view 如果传入的view为nil，则不显示提示框
 *  @param block    返回获取版本的结果 如果返回的值不为空，则是下载链接地址，直接跳转到此地址就可以更新版本
 */
-(void)getVersionForServer:(UIView *)backView VersionBlock:(void(^)(NSString *strDownURL))block;


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
          ResultBlock:(void(^)(BOOL isSend))block;



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
                 ImagePath:(NSString *)strImagePath ResultBlock:(void(^)(NSDictionary *dicResult))block;


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
               ResultBlock:(void(^)(BOOL isUpdate,long updateSize))block;


/**
 *  根据用户选择下载首页图文信息 并保存到数据库
 *
 *  @param intVersion  图文版本号
 *  @param intPage     页数 第几页
 *  @param intPageSize 每页多少条数据
 *  @param block       返回是否下载并保存成功 返回YES则保存成功
 */
-(void)downHomeImages:(int)intVersion Page:(int)intPage PageSize:(int)intPageSize
          ResultBlock:(void(^)(BOOL isSave))block;




#pragma mark 签到或分享加分的接口
/**
 *  签到或分享获取积分的接口
 *
 *  @param viewBack     提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param intType      （type:1签到，2:分享）
 *  @param block        返回block 如果返回值为NO，则获取积分失败
 */
-(void)setSignInToServer:(UIView *)viewBack Type:(int)intType ResultBlock:(void(^)(NSDictionary *dicResult))block;

#pragma mark 获取我的房间列表
/**
 *  获取我的房间列表 根据小区id获取对应的房间列表 小区号为空则返回全部的房间
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strCommunityId communityId不是必须「当不传值时，查询出所有小区我的房子」
 *  @param block          返回block 如果返回值为空则获取失败
 */
-(void)getRoomListForServer:(UIView *)viewBack CommunityId:(NSString *)strCommunityId
                ResultBlock:(void(^)(NSArray *arrList))block;

#pragma mark 获取我的授权人列表
/**
 *  根据用户id 查询我的授权人列表
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strHouseId     房间的主键id 查看哪个房间的授权人就传入哪个主键
 *  @param block          返回block 如果返回值为空则获取失败
 */
-(void)getEmpowerListForServer:(UIView *)viewBack HouseID:(NSString *)strHouseId
                   ResultBlock:(void(^)(NSArray *arrList))block;

#pragma mark 添加我的授权人
/**
 *  根据用户id 查询我的授权人列表
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param arrEmpower     数组 授权人数组
 *  @param block          返回block 如果返回值为空则获取失败
 */
-(void)addEmpowerToServer:(UIView *)viewBack EmpowerList:(NSMutableArray *)arrEmpower
              ResultBlock:(void(^)(BOOL isSave))block;


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
                 ResultBlock:(void(^)(BOOL isDelete))block;


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
                 ResultBlock:(void(^)(BOOL isSave))block;

#pragma mark 个人保镖/紧急救助个人基本资料展现接口
/**
 *  个人保镖/紧急救助个人基本资料展现接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回值block 如果返回为nil则获取失败
 */
-(void)getBasicInfoForServer:(UIView *)viewBack ResultBlock:(void(^)(NSDictionary *dicResult))block;

#pragma mark 个人保镖/紧急救助个人基本资料保存接口
/**
 *  个人保镖/紧急救助个人基本资料保存接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param dicInfo  基本资料集合 字典
 *  @param block    返回值block 如果返回为nil则保存失败
 */
-(void)saveBasicInfoToServer:(UIView *)viewBack BasicInfo:(NSDictionary *)dicInfo
                 ResultBlock:(void(^)(NSDictionary *dicResult))block;

#pragma mark 紧急救助个人医疗信息展现接口
/**
 *  紧急救助个人医疗信息展现接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回值block 如果返回为nil则获取失败
 */
-(void)getMedicalForServer:(UIView *)viewBack ResultBlock:(void(^)(NSDictionary *dicResult))block;


#pragma mark 紧急救助个人医疗信息保存接口
/**
 *  紧急救助个人医疗信息保存接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param dicInfo  医疗信息集合 数组
 *  @param block    返回值block 如果返回为nil则保存失败
 */
-(void)saveMedicalToServer:(UIView *)viewBack MedicalInfo:(NSDictionary *)dicInfo
               ResultBlock:(void(^)(NSDictionary *dicResult))block;

#pragma mark 删除医疗信息
/**
 *  根据医疗id 删除对应的医疗信息
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strMedicalId   id 医疗id
 *  @param block          返回block 如果返回值为空则删除失败
 */
-(void)deleteMedicalToServer:(UIView *)viewBack MedicalId:(NSString *)strMedicalId
                 ResultBlock:(void(^)(BOOL isDelete))block;

#pragma mark 紧急联系人信息展现接口
/**
 *  紧急联系人信息展现接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回值block 如果返回为nil则获取失败
 */
-(void)getContactersForServer:(UIView *)viewBack ResultBlock:(void(^)(NSArray *arrList))block;


#pragma mark 紧急联系人信息保存接口
/**
 *  紧急联系人信息保存接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param arrInfo  紧急联系人集合 数组
 *  @param block    返回值block 如果返回为nil则保存失败
 */
-(void)saveContactersToServer:(UIView *)viewBack ContactInfo:(NSArray *)arrInfo
                  ResultBlock:(void(^)(NSDictionary *dicResult))block;

#pragma mark 删除紧急联系人接口
/**
 *  根据医疗id 删除对应的紧急联系人
 *
 *  @param viewBack       提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strContacterId id 紧急联系人id
 *  @param block          返回block 如果返回值为空则删除失败
 */
-(void)deleteContacterToServer:(UIView *)viewBack ContacterId:(NSString *)strContacterId
                   ResultBlock:(void(^)(BOOL isDelete))block;


#pragma mark 从AppStore获取更新数据
/**
 *  从AppStore获取更新版本 根据返回block值判断是否有更新 如果返回为nil则更新失败或者没有更新版本
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回值block 如果返回值为nil则更新失败或者没有更新版本 否则返回更新版本链接
 */
-(void)getUpdateVersionForAPPStore:(UIView *)viewBack ResultBlock:(void(^)(NSString *strUrl))block;

#pragma mark 从fir上获取更新版本
/**
 *  检查从FIR上获取安居宝更新版本的信息
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param block    返回block 返回版本信息 如果返回nil则没有版本更新
 */
-(void)getVersionForFir:(UIView *)viewBack ResultBlock:(void(^)(NSDictionary *dicResult))block;


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
                       VerifiNum:(NSString *)strVerifi ResultBlock:(void(^)(BOOL isRight))block;


#pragma mark 安全度邮箱账号验证
/**
 *  安全度邮箱账号验证
 *
 *  @param viewBack  提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strEmail  邮箱号码
 *  @param block     返回block 如果返回为YES则验证成功 否则失败
 */
-(void)verificationEmailToServer:(UIView *)viewBack Email:(NSString *)strEmail
                     ResultBlock:(void(^)(BOOL isRight))block;

/**
 *  @Author Johnson, 14-12-02 16:12:17
 *
 *  获取一呼百应跟个人保镖的剩余套餐数
 *
 *  @param beforeBlock 在网络请求之前调用的block
 *  @param resultBlock 请求结果， 如果isSuccessed为YES则获取成功，反之失败
 */
+ (void)getRemainingPackagesBeforeBlock:(void(^)(void))beforeBlock resuleBlock:(void(^)(BOOL isSuccessed, id result))resultBlock;

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
                      VerifiNum:(NSString *)strCode ResultBlock:(void(^)(BOOL isRight))block;

/**
 *  重置密码提交接口地址
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strPhone 传入需要重置密码的手机账号
 *  @param strPwd   传入修改的密码
 *  @param block    返回接口 如果返回yes则修改成功 否则失败
 */
-(void)forgetPhoneToServer:(UIView *)viewBack PhoneNum:(NSString *)strPhone
                  ResetPwd:(NSString *)strPwd ResultBlock:(void(^)(BOOL isRight))block;

/**
 *  使用邮箱账号找回密码接口
 *
 *  @param viewBack 提示信息的背景View，默认传值self.view 如果为nil，则不显示提示信息
 *  @param strEmail 邮箱账号
 *  @param block    返回接口 如果返回YES则成功 否则失败
 */
-(void)forgetEmailToServer:(UIView *)viewBack Email:(NSString *)strEmail
               ResultBlock:(void(^)(BOOL isRight))block;

- (void)callLogToServer;
@end
