//
//  GameObject.m
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-05.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GameObject.h"

@interface GameObject()
{
    
    
}


@end

@implementation GameObject

-(void)onCollision:(GameObject*)otherObject
{
//    NSLog(@"Something Hit an Object!");
    if (![otherObject.name isEqualToString:@"player"])
        self.speed = -self.speed;
}

@end
