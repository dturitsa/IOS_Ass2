//
//  Mix.h
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-14.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

#import <Foundation/Foundation.h>

struct CPlusPlusClass;

@interface Mix : NSObject
{
@private
    struct CPlusPlusClass *cPlusPlusObject;
}


-(int)incrementCppVal;

@end
