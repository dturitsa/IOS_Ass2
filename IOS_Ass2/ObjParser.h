//
//  ObjParser.hpp
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-14.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
//struct CPlusPlusClass;

@interface VertexObj : NSObject
{
@public
    GLKVector3 v;
    GLKVector3 n;
    GLKVector2 t;
}
@end

@interface ObjParser : NSObject
{
    
@private
    //struct CPlusPlusClass *cPlusPlusObject;
}

//-(int)parseFile :(NSString *)file;
-(void)parseFile;

@end


