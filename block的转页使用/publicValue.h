//
//  publicValue.h
//  block的转页使用
//
//  Created by iiiiiiiii on 15/5/19.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface publicValue : NSObject
@property (nonatomic, assign) BOOL isLogin;
@property (nonatomic,strong)NSMutableDictionary *userInof;

+(publicValue *)shareValue;

@end
