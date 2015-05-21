//
//  DGPublicValue.m
//  DaoGouTest
//
//  Created by 1140 on 15-3-25.
//  Copyright (c) 2015年 1140. All rights reserved.
//

#import "DGPublicValue.h"

@implementation DGPublicValue

@synthesize allGoodsPrice;
@synthesize orderGoodsArr;
@synthesize GoodsNumber;
@synthesize referer;
@synthesize UserID;
@synthesize strToken;
@synthesize latitude,longitude;
@synthesize ShopID;
@synthesize userInof;

static DGPublicValue *pubValue = nil;
+(DGPublicValue *)shareValue
{
    if(pubValue == nil)
    {
        @synchronized(self)
        {
            if(pubValue == nil)
            {
                pubValue = [[DGPublicValue alloc] init];
                pubValue.orderGoodsArr = [[NSMutableArray alloc] init];
                pubValue.allGoodsPrice = 0;
                pubValue.GoodsNumber = 0;
                pubValue.userInof = [[NSMutableDictionary alloc] init];
            }
        }
    }
    return pubValue;
}

@end
