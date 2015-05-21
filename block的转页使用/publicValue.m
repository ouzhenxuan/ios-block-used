//
//  publicValue.m
//  block的转页使用
//
//  Created by iiiiiiiii on 15/5/19.
//  Copyright (c) 2015年 ozx. All rights reserved.
//

#import "publicValue.h"

@implementation publicValue

static publicValue *Value = nil;
+(publicValue *)shareValue
{
    if(Value == nil)
    {
        @synchronized(self)
        {
            if(Value == nil)
            {
                Value = [[publicValue alloc] init];
                Value.userInof = [[NSMutableDictionary alloc] init];
            }
        }
    }
    return Value;
}



@end
