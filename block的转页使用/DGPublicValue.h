//
//  DGPublicValue.h
//  DaoGouTest
//
//  Created by 1140 on 15-3-25.
//  Copyright (c) 2015年 1140. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DGPublicValue : NSObject

@property (nonatomic ,assign) float allGoodsPrice; //总价
@property (nonatomic ,strong) NSMutableArray *orderGoodsArr;//已选商品
@property (nonatomic ,assign) int GoodsNumber;//商品个数


@property (nonatomic,strong) NSString *referer;//上次发起网络请求的地址

@property (nonatomic,strong)NSMutableDictionary *userInof;//用户的信息集合
@property (nonatomic,strong)NSString *ShopID;//店铺ID
@property (nonatomic,strong)NSString *UserID;//用户ID
@property (nonatomic,strong)NSString *strToken;//用户认证Token
@property (nonatomic,strong)NSString *latitude;//纬度
@property (nonatomic,strong)NSString *longitude;//经度
@property (nonatomic, assign) BOOL isLogin;

+(DGPublicValue *)shareValue;





@end
