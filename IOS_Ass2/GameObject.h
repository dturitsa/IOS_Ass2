//
//  GameObject.h
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-05.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

#ifndef GameObject_h
#define GameObject_h
#import <GLKit/GLKit.h>
//#import "GOTypes.h"

@interface GameObject : NSObject

typedef struct
{
    GLuint vArray; //pointer to vertex array
    GLuint vBuffer; //pointer to vertex buffer
    int   length; //# of vertices
    GLuint textureHandle;//the texture of the object
    
} VertexInfo;

@property GLKVector3 position;
@property GLKVector3 rotation;
@property GLKVector3 modelRotation;
@property GLKVector3 scale;

@property NSString* modelName;
@property VertexInfo modelHandle;

@property NSString* textureName;


@end



#endif /* GameObject_h */
